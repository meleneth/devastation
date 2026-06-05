# devastation

`devastation` builds an idempotent local-first development environment for a Debian or Ubuntu laptop. It uses Ansible, Docker Compose, CoreDNS, a local offline CA, a standalone Docker registry, apt-cacher-ng, KIND, GitLab CE, GitLab Runner, and Neovim.

The internal DNS root is `deva.station`.

## Architecture

Persistent state defaults to `/srv/devastation`:

- `/srv/devastation/compose`: generated Docker Compose project
- `/srv/devastation/dns`: CoreDNS configuration
- `/srv/devastation/ca`: offline local root CA material, mode `0700`
- `/srv/devastation/certs`: generated leaf certificates
- `/srv/devastation/secrets`: generated secrets, mode `0700`
- `/srv/devastation/registry`: standalone local registry data
- `/srv/devastation/apt-cache`: apt-cacher-ng cache data
- `/srv/devastation/kind`: KIND cluster config
- `/srv/devastation/gitlab`: GitLab config, logs, and data
- `/srv/devastation/gitlab-runner`: GitLab Runner config

Core services run on the Docker network `devastation` with static addresses in `172.30.42.0/24`. CoreDNS serves `deva.station` and forwards everything else to configurable upstream resolvers.

## Quick Start

Install Ansible if it is not already present:

```bash
sudo apt-get update
sudo apt-get install -y ansible
```

Bring the environment up:

```bash
./bin/devastation-up
```

Run full validation:

```bash
./bin/devastation-validate
```

Run only Ansible syntax checks before changing a machine:

```bash
ansible-playbook --syntax-check playbooks/bootstrap.yml
```

Most settings live in `group_vars/all.yml`, including paths, package lists, host resolver behavior, GitLab migration gates, registry auth, and Docker socket use for the runner.

## User Setup

The `user_setup` role installs language version managers for the target user:

- `pyenv` in `~/.pyenv`
- `rbenv` in `~/.rbenv`
- `ruby-build` as an rbenv plugin
- `nvm` in `~/.nvm`

Initialization blocks are added to the configured profile, defaulting to `~/.profile`. The role does not install Python, Ruby, or Node versions by default; it installs the managers so you can choose versions locally.

The `fonts` role installs the patched MesloLGS Nerd Font files system-wide under `/usr/local/share/fonts/devastation/MesloLGS` and refreshes the font cache.

## Hostnames

These names are served under `deva.station`:

- `dns.deva.station`
- `ca.deva.station`
- `registry.deva.station`
- `apt-cache.deva.station`
- `gitlab.deva.station`
- `runner.deva.station`
- `kind.deva.station`
- `grafana.deva.station`, reserved
- `jaeger.deva.station`, reserved
- `prometheus.deva.station`, reserved

## Registry

The canonical local Kubernetes registry is `registry.deva.station` over HTTPS with the local root CA. Host Docker trusts the CA through `/etc/docker/certs.d/registry.deva.station/ca.crt`; KIND nodes receive `/etc/containerd/certs.d/registry.deva.station/hosts.toml` and the CA certificate.

Acceptance flow:

```bash
./bin/devastation-validate
```

That builds `registry.deva.station/devastation/hello:local`, pushes it, pulls it, deploys it into KIND, and verifies DNS from a pod.

Registry auth is disabled by default for simple local use. Set `registry_enable_auth: true` only after adding htpasswd material under `/srv/devastation/registry/auth/htpasswd`.

## Apt Cache

Host apt uses:

```text
Acquire::http::Proxy "http://apt-cache.deva.station:3142";
Acquire::https::Proxy "DIRECT";
```

Refresh useful package and image caches while on fast internet:

```bash
./bin/devastation-refresh-caches
```

Dockerfile snippet for internal builds:

```dockerfile
RUN printf 'Acquire::http::Proxy "http://apt-cache.deva.station:3142";\nAcquire::https::Proxy "DIRECT";\n' \
  > /etc/apt/apt.conf.d/01devastation-proxy
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates curl
```

If a package is unavailable offline, apt will fail clearly. Refresh the cache when you next have fast internet.

## DNS Notes

CoreDNS runs in Docker and binds `127.0.0.1:53` for host access. Ansible can configure `systemd-resolved` with a drop-in at `/etc/systemd/resolved.conf.d/devastation.conf`, using split DNS for `deva.station`.

Rollback:

```bash
sudo rm -f /etc/systemd/resolved.conf.d/devastation.conf
sudo systemctl restart systemd-resolved
docker compose -f /srv/devastation/compose/compose.yml stop dns
```

Set `dns_configure_host_resolver: false` to leave host resolver settings untouched.

## Certificate Notes

The CA role creates an offline root:

- `/srv/devastation/ca/root-ca.key`, mode `0600`
- `/srv/devastation/ca/root-ca.crt`

The root certificate is installed into host trust when `ca_install_host_trust: true`.

Mint an extra certificate:

```bash
./bin/devastation-mint-cert service.deva.station
```

The script refuses names outside `deva.station`.

## GitLab

GitLab CE runs at `https://gitlab.deva.station` and exposes SSH on host port `2222`. GitLab stores persistent data under `/srv/devastation/gitlab`.

The playbook stops before touching existing GitLab data unless one of these is true:

- `gitlab_allow_existing_data: true`
- `gitlab_migration_enabled: true` with all required migration variables set

Backup:

```bash
./bin/devastation-gitlab-backup
```

Restore:

```bash
./bin/devastation-gitlab-restore /path/to/gitlab_backup.tar
```

See `docs/migration-gitlab.md` for migration from an existing Docker install.

## GitLab Runner

The runner uses the Docker executor. Docker socket mounting is disabled by default because it gives jobs host-level Docker control. To enable the pragmatic local mode:

```yaml
gitlab_runner_mount_docker_socket: true
```

Automatic registration happens only when `gitlab_runner_registration_token` is supplied. Otherwise the playbook prints the exact rerun variable to use.

## Recovery Commands

Restart services:

```bash
docker compose -f /srv/devastation/compose/compose.yml restart
```

Stop services without deleting data:

```bash
./bin/devastation-down
```

Reset KIND only:

```bash
./bin/devastation-kind-reset
```

Inspect logs:

```bash
docker compose -f /srv/devastation/compose/compose.yml logs -f dns registry apt-cache gitlab gitlab-runner
```

Regenerate by convergence:

```bash
./bin/devastation-up
```

## Security Posture

No secrets are committed. CA private keys and generated secret directories are not world-readable. Dangerous options are explicit in `group_vars/all.yml`:

- `docker_insecure_registry_fallback`
- `gitlab_allow_existing_data`
- `gitlab_migration_enabled`
- `gitlab_runner_mount_docker_socket`

Privileged surfaces are documented here: Docker itself, GitLab in Docker, KIND nodes, and optional Docker socket mounting for runner jobs.
