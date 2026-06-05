# devastation

`devastation` builds an idempotent local-first development environment for a Debian or Ubuntu laptop. It uses Ansible, Docker Compose, CoreDNS, an ephemeral local root CA workflow, a standalone Docker registry, apt-cacher-ng, KIND, GitLab CE, GitLab Runner, and Neovim.

The internal DNS root is `deva.station`.

## Architecture

Persistent state defaults to `/srv/devastation`:

- `/srv/devastation/compose`: generated Docker Compose project
- `/srv/devastation/dns`: CoreDNS configuration
- `/srv/devastation/ca`: retained local root CA certificate only, mode `0700`
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

The `fonts` role installs the patched MesloLGS Nerd Font files from `romkatv/powerlevel10k-media` system-wide under `/usr/local/share/fonts/devastation/MesloLGS` and refreshes the font cache.

The `neovim` role installs the latest official upstream Linux x86_64 Neovim release from GitHub, links it at `/usr/local/bin/nvim`, and removes the old distro `neovim` package by default. It installs LazyVim from the official starter repo only when no user config exists. If the previous generated minimal devastation config is present, it is moved aside to a timestamped backup before LazyVim is installed.

Refresh the official Neovim tarball intentionally:

```bash
./bin/devastation-up -e neovim_force_official_download=true
```

## Hostnames

These names are served under `deva.station`:

- `dns.deva.station`
- `ca.deva.station`
- `registry.deva.station`
- `registry-cache.deva.station`
- `apt-cache.deva.station`
- `gitlab.deva.station`
- `runner.deva.station`
- `kind.deva.station`
- `otel-collector.deva.station`
- `grafana.deva.station`
- `jaeger.deva.station`
- `prometheus.deva.station`
- `loki.deva.station`
- `node-exporter.deva.station`
- `cadvisor.deva.station`
- `vault.deva.station`
- `eventline.deva.station`
- `test-db.deva.station`
- `development-db.deva.station`
- `production-db.deva.station`
- `otel-db.deva.station`

## Registry

The canonical local Kubernetes registry is `registry.deva.station` over HTTPS with the local root CA. The pull-through Docker Hub cache is `registry-cache.deva.station`. Host Docker trusts the CA through `/etc/docker/certs.d/registry.deva.station/ca.crt`; KIND nodes receive `/etc/containerd/certs.d/registry.deva.station/hosts.toml` and the CA certificate.

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

CoreDNS runs in Docker and binds `127.0.0.1:53` for host access. Service names are mapped to fixed addresses on the private Docker bridge defined by `devastation_subnets.services`, defaulting to `172.30.42.0/24`; the `devastation_dns_records` list is the source of truth for CoreDNS and `/etc/hosts`. Ansible also writes static `deva.station` entries to `/etc/hosts` by default so browser and CLI access work even on systems without `systemd-resolved`. If `systemd-resolved` is present, Ansible configures a drop-in at `/etc/systemd/resolved.conf.d/devastation.conf`, using split DNS for `deva.station`.

Rollback:

```bash
sudo rm -f /etc/systemd/resolved.conf.d/devastation.conf
sudo sed -i '/BEGIN DEVASTATION DEVA.STATION HOSTS/,/END DEVASTATION DEVA.STATION HOSTS/d' /etc/hosts
sudo systemctl restart systemd-resolved
docker compose -f /srv/devastation/compose/compose.yml stop dns
```

Set `dns_configure_host_resolver: false` to leave systemd-resolved settings untouched. Set `dns_configure_hosts_file: false` to avoid writing `/etc/hosts`.

## Certificate Notes

The CA role uses an ephemeral root CA private key. During bootstrap or rotation it creates a temporary root CA key in a staging directory, signs every configured local leaf certificate, validates the full chain, installs trust, and immediately destroys the root CA private key. The private key is intentionally not backed up or retained. Reproducibility beats preservation here.

Retained artifacts:

- `/srv/devastation/ca/root-ca.crt`
- `/srv/devastation/certs/*/tls.crt`
- `/srv/devastation/certs/*/tls.key`, mode `0600`

Destroyed artifacts:

- the temporary root CA private key
- generated CSRs
- OpenSSL serial and config scratch files
- any legacy `/srv/devastation/ca/root-ca.key`

The root certificate is installed into host trust when `ca_install_host_trust: true`. The CA role also installs the root into the target user's NSS trust databases when `ca_install_browser_nss_trust: true`, covering current Chromium-style `~/.local/share/pki/nssdb` trust, legacy `~/.pki/nssdb` trust, and existing Firefox profiles under `~/.mozilla/firefox`. Docker receives registry trust under `/etc/docker/certs.d/registry.deva.station/ca.crt`; KIND nodes receive containerd trust when they exist; GitLab Runner sees the retained root certificate through its mounted config.

After rerunning the playbook, restart your browser before checking `https://gitlab.deva.station`. If Firefox creates a new profile later, rerun `./bin/devastation-up` to add the root CA to that new profile.

Rotate the full trust universe:

```bash
./bin/devastation-rotate-trust-universe
```

New hostnames require a full automated rotation because there is no retained CA private key for single-certificate issuance. Add hostnames to `devastation_internal_hostnames` and add required leaf cert names to `ca_leaf_certificates` in `group_vars/all.yml`, then run the rotation command. `./bin/devastation-mint-cert` intentionally refuses single-certificate minting.

## GitLab

## Data And Observability

The compose project includes local dev data services and an observability stack:

- Vault dev server: `http://vault.deva.station:8200`, root token `devastation`
- Eventline GoAWS SNS/SQS emulator: `http://eventline.deva.station:4100`
- Postgres 18 containers: `test-db`, `development-db`, `production-db`, and `otel-db`
- Grafana: `http://grafana.deva.station:3000`, admin password `devastation`
- Prometheus: `http://prometheus.deva.station:9090`
- Jaeger v2: `http://jaeger.deva.station:16686`
- Loki: `http://loki.deva.station:3100`
- OTLP collector endpoint: `otel-collector.deva.station:4317` for gRPC and `:4318` for HTTP

Grafana is provisioned with Prometheus, Loki, Jaeger, and all four Postgres databases as data sources. Starter dashboards are generated under `/srv/devastation/observability/grafana/dashboards`. Prometheus scrapes node-exporter, cAdvisor, the registry metrics endpoints, Grafana, Loki, Vault, OTel Collector, and Postgres exporters.

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

Automatic registration happens only when `gitlab_runner_authentication_token` is supplied. Otherwise the playbook prints the exact rerun variable to use.

To create the token:

1. Open `https://gitlab.deva.station`.
2. Sign in as an administrator.
3. Go to `Admin Area` -> `CI/CD` -> `Runners`.
4. Choose `New instance runner`.
5. Set the runner description to `runner.deva.station`.
6. Add tags such as `local`, `devastation`, and `docker`.
7. Create the runner and copy the `glrt-...` authentication token.

Then run:

```bash
./bin/devastation-up -e gitlab_runner_authentication_token='glrt-REDACTED'
```

The older `gitlab_runner_registration_token` variable is still accepted as a legacy fallback, but GitLab 17 disables deprecated registration tokens by default.

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
docker compose -f /srv/devastation/compose/compose.yml logs -f dns registry apt-cache gitlab gitlab-runner prometheus grafana loki jaeger otel-collector vault
```

Regenerate by convergence:

```bash
./bin/devastation-up
```

Rotate certificates and reinstall trust:

```bash
./bin/devastation-rotate-trust-universe
```

## Security Posture

No secrets are committed. The root CA private key is an ephemeral build artifact and is destroyed after signing; validation fails if `/srv/devastation/ca/root-ca.key` exists after rotation. Generated secret directories are not world-readable. Dangerous options are explicit in `group_vars/all.yml`:

- `docker_insecure_registry_fallback`
- `gitlab_allow_existing_data`
- `gitlab_migration_enabled`
- `gitlab_runner_mount_docker_socket`

Privileged surfaces are documented here: Docker itself, GitLab in Docker, KIND nodes, and optional Docker socket mounting for runner jobs.
