# Transparent package caching

Devastation makes supported package managers use local caches without adding
mirror settings to project repositories or Dockerfiles. This document explains
the shared mechanism and the currently supported RubyGems, npm, and PyPI paths.

The behavioral contract is defined in [requirements.md](requirements.md). This
page describes the implementation and its operational consequences.

## Request flow

An untouched container continues to use the public package URL it already
knows:

```text
RubyGems client          npm client               pip client
rubygems.org             registry.npmjs.org       pypi.org/simple
              \              |                  /
               Docker/CoreDNS override
                         |
                  172.17.0.1:443
                         |
              shared nginx TLS frontend
             /             |              \
        Gemstash       Verdaccio         devpi
            |              |               |
      rubygems.org   registry.npmjs.org  pypi.org
         upstream       upstream         upstream
```

CoreDNS resolves the intercepted public names to the host-side Docker bridge
gateway. nginx terminates TLS there and selects the correct local cache using
SNI and the HTTP `Host` header. Gem payloads go to Gemstash, npm metadata and
tarballs go to Verdaccio, and PyPI simple-index requests and distributions go
to devpi.

The PyPI frontend maps public `/simple/` requests to devpi's
`/root/pypi/+simple/` index. devpi's relative distribution links consequently
resolve at public `/+f/`; nginx maps that content-addressed namespace back to
`/root/pypi/+f/`.

The cache containers use the host's real upstream DNS servers rather than
Devastation CoreDNS. This is essential: if a cache backend resolved its
own public upstream through the interception rule, it would call itself in a
loop.

Gemstash redirects Bundler's compact-index requests to `index.rubygems.org`.
The frontend forwards that metadata endpoint to the real public index while
the `.gem` payload path remains cached by Gemstash.

## Container trust injection

The intercepted endpoints present certificates signed by the Devastation root
CA. Stock containers do not normally trust that CA, even when the host does.

Devastation installs a small `runc` shim as Docker's default OCI runtime. Before
`runc create` or `runc run`, the shim modifies that container's OCI bundle to:

- bind-mount `/srv/devastation/workload-trust` read-only at
  `/etc/devastation`;
- set `SSL_CERT_FILE` for Ruby/OpenSSL clients;
- set `BUNDLE_SSL_CA_CERT` for Bundler;
- set `NODE_EXTRA_CA_CERTS` for Node.js and npm.
- set `PIP_CERT` and `REQUESTS_CA_BUNDLE` for pip and Python HTTP clients.

The shim delegates every other operation to the distribution's real
`/usr/sbin/runc`. Docker's service PATH also places the shim ahead of the system
binary, which makes the same injection apply to BuildKit's OCI worker. This is
why both `docker run` and `RUN` instructions work without project changes.

Explicit environment settings supplied by a container are preserved. The shim
adds only missing trust variables.

## Certificate scope and rotation

Intercepted public names use dedicated leaves:

| Certificate | Allowed public names |
| --- | --- |
| `rubygems-transparent` | `rubygems.org`, `index.rubygems.org` |
| `npm-transparent` | `registry.npmjs.org` |
| `pypi-transparent` | `pypi.org` |

The CA generator verifies both directions: each interception leaf must contain
its assigned names, and every unrelated leaf must not contain them. This keeps
an internal service key from authenticating as a public package registry.

Devastation intentionally destroys the root CA private key after certificate
issuance. Adding or changing an intercepted hostname therefore requires a full
trust-universe rotation. Rotation reissues all local leaves, republishes the
combined workload bundle, restarts Docker, and recreates services that consume
rotated certificates.

Run the focused convergence playbooks rather than the full bootstrap when only
one cache path changed:

```bash
ansible-playbook -i inventory/localhost.yml playbooks/rubygems-cache.yml
ansible-playbook -i inventory/localhost.yml playbooks/npm-cache.yml
ansible-playbook -i inventory/localhost.yml playbooks/pypi-cache.yml
```

Because rotation restarts Docker, unattended automation should launch the
playbook from a host service or another process that survives a Docker daemon
restart.

## Shared TLS frontend

Only one process can bind the Docker bridge gateway's port 443. RubyGems, npm, and PyPI
therefore share `gem-cache-transparent`, despite its historical service name.
nginx selects a certificate and backend by hostname.

The local Docker registry listens on its fixed Devastation-network address
`172.30.42.12:443`; it must not publish `0.0.0.0:443`, because that would also
reserve `172.17.0.1:443` and prevent the interception frontend from starting.

When the bind-mounted nginx configuration changes, the package-cache role
restarts the frontend so nginx actually loads the new content. A Compose `up`
alone does not necessarily restart a container when only a bind-mounted file's
contents changed.

## Persistent data and observability

Cache payloads survive container recreation under:

- npm: `/srv/devastation/package-caches/verdaccio/storage`;
- PyPI: `/srv/devastation/package-caches/devpi/data`;
- RubyGems: `/srv/devastation/package-caches/gemstash/data`.

Inspect all caches with:

```bash
bin/devastation-cache-stats
bin/devastation-cache-stats --json
```

Gemstash stores a gem payload in a file literally named `gem`, not with a
`.gem` suffix. The dashboard accounts for that storage layout. Verdaccio keeps
npm payloads as `.tgz` files.
devpi 6 stores distribution bodies in its SQLite keyfs database, so the
dashboard counts `STAGEFILE` records under the index's `+f` namespace rather
than looking for loose files with archive extensions.

Useful live checks:

```bash
docker compose -f /srv/devastation/compose/compose.yml \
  ps dns gem-cache-transparent gem-cache npm-cache pypi-cache

docker compose -f /srv/devastation/compose/compose.yml \
  logs -f gem-cache-transparent gem-cache npm-cache pypi-cache

docker run --rm ruby:latest gem fetch rake --silent
docker run --rm node:latest npm pack is-number --silent
docker run --rm python:latest python -m pip download --no-deps --dest /tmp requests
```

The frontend access log is the clearest proof that an untouched client used the
intercepted path. Persistent artifact counts prove that the backend cache wrote
the payload.

## Validation

`devastation-validate` checks public-name DNS interception and performs real
package downloads from stock runtime images. Its non-quick path also builds
stock Ruby, Node, and Python Dockerfiles containing ordinary package-manager commands.

These checks deliberately test behavior rather than merely checking that a
cache port accepts connections.

## Adding another language ecosystem

Add one ecosystem at a time:

1. Define its transparent behavior and stock-client acceptance command in
   `docs/requirements.md`.
2. Add a dedicated interception leaf and hostname mapping in
   `group_vars/all.yml`.
3. Add the public hostname to CoreDNS interception.
4. Give the cache backend direct upstream DNS to prevent recursion.
5. Add an SNI server to the shared TLS frontend and mount only its dedicated
   certificate.
6. Add the client runtime's CA environment variable to the OCI shim only if the
   existing variables are insufficient.
7. Add runtime and BuildKit acceptance checks.
8. Rotate the trust universe, converge the focused playbook, and confirm that
   persistent artifact counts increase.

Do not add an intercepted public hostname to every leaf certificate, and do not
start another listener on `172.17.0.1:443`.

## Troubleshooting

`UNABLE_TO_VERIFY_LEAF_SIGNATURE` from npm means the container did not receive
`NODE_EXTRA_CA_CERTS` or the mounted bundle. Check:

```bash
docker run --rm node:latest sh -c \
  'echo "$NODE_EXTRA_CA_CERTS"; test -s /etc/devastation/ca-certificates.crt'
```

Ruby certificate failures use the corresponding `SSL_CERT_FILE` check.
For pip, inspect `PIP_CERT`, `REQUESTS_CA_BUNDLE`, and the mounted bundle:

```bash
docker run --rm python:latest sh -c \
  'echo "$PIP_CERT"; echo "$REQUESTS_CA_BUNDLE"; test -s /etc/devastation/ca-certificates.crt'
```

An nginx frontend stuck in `Created` usually indicates a duplicate service IP
or another process bound to `172.17.0.1:443`. Inspect Compose status and Docker
port bindings.

Successful DNS interception with recursive requests or timeouts usually means
the cache backend accidentally uses Devastation CoreDNS instead of the direct
upstream resolver list.

The caches guarantee persistent payload storage. Some package managers still
need current upstream metadata to resolve an unconstrained package name; a
cached payload alone does not make every dependency-resolution operation fully
offline.
