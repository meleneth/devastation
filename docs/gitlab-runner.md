# GitLab And Runner

GitLab runs at `https://gitlab.deva.station`.

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

## Create The Runner Token

GitLab 17 uses runner authentication tokens. The value starts with `glrt-`.

1. Sign in as an administrator.
2. Open `Admin Area`.
3. Open `CI/CD` -> `Runners`.
4. Choose `New instance runner`.
5. Use a description like `runner.deva.station`.
6. Add tags such as `local`, `devastation`, and `docker`.
7. Create the runner.
8. Copy the `glrt-...` authentication token.

## Register The Runner

Rerun convergence with the token:

```bash
./bin/devastation-up -e gitlab_runner_authentication_token='glrt-REDACTED'
```

The runner uses the Docker executor. Docker socket mounting is disabled by default because it gives jobs host-level Docker control.

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
