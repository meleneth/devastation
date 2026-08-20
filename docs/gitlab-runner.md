# GitLab And Runner

GitLab runs at `https://gitlab.deva.station`.

Sign in through **Devastation IAM** using any enabled account in the Keycloak
`devastation` realm at `https://iam.deva.station`. GitLab creates the
corresponding account on first sign-in from its verified email address and
preferred username. Local GitLab password authentication remains enabled as a
recovery path for the `root` administrator.

The GitLab role installs the Devastation root CA into the Omnibus-specific
`/etc/gitlab/trusted-certs` store. This is required for Rails and OmniAuth even
though the shared workload CA environment is sufficient for tools such as
`curl`.

## First Administrator Sign-In

The first administrator account is `root`.

Read the initial password on the host:

```bash
sudo cat /srv/devastation/gitlab/config/initial_root_password
```

Sign in as `root`, then create your normal user account from the GitLab UI. Keep the root account for administration.

## Approve Your User

If sign-up approval is required:

1. Sign in as `root`.
2. Open `Admin Area`.
3. Open `Overview` -> `Users`.
4. Select the pending user.
5. Approve the user.

After approval, sign out of `root` and sign in as your normal user.

## Runner Registration

Ansible automatically creates and registers the `runner.deva.station` instance
runner by default. Its `glrt-*` authentication token is retained with mode
`0600` under `/srv/devastation/gitlab-runner/config/` so an interrupted
registration can be retried without creating duplicate runners.

Set `gitlab_runner_auto_register: false` to disable this behavior. An explicit
`gitlab_runner_authentication_token` remains available as an override.

The runner uses the Docker executor. Docker socket mounting is disabled by default because it gives jobs host-level Docker control.

Runner job and helper containers use the `devastation` Docker network so they
can resolve private service names such as `gitlab.deva.station` through the
Devastation DNS service. Configure this with:

```yaml
gitlab_runner_docker_network_mode: devastation
```

To enable local Docker control for jobs:

```yaml
gitlab_runner_mount_docker_socket: true
```

Then rerun:

```bash
./bin/devastation-up \
  -e gitlab_runner_authentication_token='glrt-REDACTED' \
  -e gitlab_runner_mount_docker_socket=true
```

## Validate

```bash
docker compose -f /srv/devastation/compose/compose.yml ps gitlab gitlab-runner
./bin/devastation-validate --quick
```
