# Generated App Services

`devastation` includes shared services for local/generated applications. They are local-first, use `deva.station` DNS, and are bootstrapped through `./bin/devastation-up`.

## Services

| Service | Purpose | Host |
| --- | --- | --- |
| Keycloak | Shared OIDC/OAuth identity provider | `https://iam.deva.station` |
| Mailpit | Local SMTP and email inbox | `smtp.mail.deva.station:1025`, `https://mail.deva.station` |
| Playwright | Headless Chromium runner | Docker Compose service `playwright` |
| Keystone | Admin/content CRUD backend | `https://keystone.deva.station` |
| SeaweedFS | S3-compatible object storage | `https://s3.deva.station`, `https://seaweed.deva.station` |

Default credentials in this page are local-only development defaults. Do not reuse them outside the laptop environment.

## IAM

Keycloak runs the `devastation` realm with a seeded developer user, admin user, and demo OIDC client.

Users:

```text
developer / devastation-dev
admin / devastation-admin
```

Client:

```text
client_id: devastation-demo
client_secret: devastation-demo-secret
```

Downstream app settings:

```text
OIDC_ISSUER=https://iam.deva.station/realms/devastation
OIDC_CLIENT_ID=devastation-demo
OIDC_CLIENT_SECRET=devastation-demo-secret
OIDC_AUTH_URL=https://iam.deva.station/realms/devastation/protocol/openid-connect/auth
OIDC_TOKEN_URL=https://iam.deva.station/realms/devastation/protocol/openid-connect/token
OIDC_USERINFO_URL=https://iam.deva.station/realms/devastation/protocol/openid-connect/userinfo
OIDC_JWKS_URL=https://iam.deva.station/realms/devastation/protocol/openid-connect/certs
OIDC_LOGOUT_URL=https://iam.deva.station/realms/devastation/protocol/openid-connect/logout
```

Rails OmniAuth example:

```ruby
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :openid_connect,
    name: :keycloak,
    scope: [:openid, :email, :profile],
    response_type: :code,
    issuer: ENV.fetch("OIDC_ISSUER", "https://iam.deva.station/realms/devastation"),
    client_options: {
      identifier: ENV.fetch("OIDC_CLIENT_ID", "devastation-demo"),
      secret: ENV.fetch("OIDC_CLIENT_SECRET", "devastation-demo-secret"),
      redirect_uri: "https://my-app.deva.station/auth/keycloak/callback"
    }
end
```

If login fails with a redirect mismatch, add the exact callback URL to the Keycloak client. The seeded demo client accepts `https://*.deva.station/*`, `http://localhost:*/*`, and `http://127.0.0.1:*/*`.

Smoke:

```bash
bin/devastation-iam-smoke
```

## Mailpit

Mailpit is a local capture mailbox only. It is not configured as a public internet mail server.

Settings:

```text
SMTP_HOST=smtp.mail.deva.station
SMTP_PORT=1025
SMTP_USERNAME=
SMTP_PASSWORD=
MAIL_FROM=dev@deva.station
MAIL_WEB=https://mail.deva.station
```

Rails ActionMailer:

```ruby
config.action_mailer.delivery_method = :smtp
config.action_mailer.smtp_settings = {
  address: "smtp.mail.deva.station",
  port: 1025,
  enable_starttls_auto: false
}
config.action_mailer.default_url_options = { host: "my-app.deva.station", protocol: "https" }
config.action_mailer.default_options = { from: "dev@deva.station" }
```

Smoke:

```bash
bin/devastation-mail-smoke
```

## Playwright

The `playwright` Compose service uses the official Playwright image with Chromium installed. It mounts `/srv/devastation/app-services/playwright` as `/work` and trusts the local root CA through `NODE_EXTRA_CA_CERTS`.

Built-in smoke:

```bash
bin/devastation-playwright-smoke
```

Generated projects can reuse it by mounting their project into the container:

```bash
docker compose -f /srv/devastation/compose/compose.yml exec -T playwright \
  npx playwright test /path/inside/mount
```

For project-owned stacks, copy the same image and CA mount pattern:

```yaml
services:
  playwright:
    image: registry.deva.station/devastation-mirror/mcr.microsoft.com/playwright:v1.49.1-noble
    environment:
      NODE_EXTRA_CA_CERTS: /usr/local/share/ca-certificates/devastation-root-ca.crt
    volumes:
      - /srv/devastation/ca/root-ca.crt:/usr/local/share/ca-certificates/devastation-root-ca.crt:ro
      - .:/work
```

## Keystone

Keystone is the shared local user/auth and admin/content backend with `User` and `Note` lists. Its session cookie is scoped to `deva.station`, so a login at `https://keystone.deva.station` can be reused by HTTPS generated apps under `deva.station`.

Admin:

```text
url: https://keystone.deva.station
email: admin@deva.station
password: devastation-admin
```

Persistence:

```text
database: postgres://devastation:devastation@keystone-db.deva.station:5432/keystone
image source: /srv/devastation/app-services/keystone/build
```

Generated apps can either consume Keystone as an external admin/content service or copy the checked-in `templates/keystone-*` pattern into their own stack and point it at their own Postgres database.

Browser clients must send credentials when calling Keystone:

```js
await fetch("https://keystone.deva.station/api/graphql", {
  method: "POST",
  credentials: "include",
  headers: { "content-type": "application/json" },
  body: JSON.stringify({ query: "{ authenticatedItem { ... on User { id email name } } }" }),
});
```

The shared cookie is `Secure`, `HttpOnly`, `SameSite=Lax`, and uses `Domain=deva.station`. That covers `deva.station` and subdomains such as `my-app.deva.station`; it does not cover `localhost` or plain HTTP origins.

## SeaweedFS S3

SeaweedFS provides local S3-compatible storage. It does not require real AWS access.

Settings:

```text
S3_ENDPOINT=https://s3.deva.station
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=devastation
AWS_SECRET_ACCESS_KEY=devastation-secret
S3_BUCKET=devastation-dev
S3_FORCE_PATH_STYLE=true
```

Rails Active Storage:

```yaml
local_s3:
  service: S3
  endpoint: https://s3.deva.station
  region: us-east-1
  bucket: devastation-dev
  access_key_id: devastation
  secret_access_key: devastation-secret
  force_path_style: true
```

Generic AWS SDK for JavaScript:

```js
import { S3Client } from "@aws-sdk/client-s3";

export const s3 = new S3Client({
  endpoint: "https://s3.deva.station",
  region: "us-east-1",
  credentials: {
    accessKeyId: "devastation",
    secretAccessKey: "devastation-secret",
  },
  forcePathStyle: true,
});
```

Smoke:

```bash
bin/devastation-s3-smoke
```

The bootstrap installs the distro `awscli` package so the smoke script can run from the host.

## Operations

Start or converge everything:

```bash
./bin/devastation-up
```

Restart a specific service:

```bash
docker compose -f /srv/devastation/compose/compose.yml restart iam mail keystone seaweed app-gateway
```

Rebuild Keystone after template changes:

```bash
./bin/devastation-up --tags app_services
```

If tags are not in use for a local run, `./bin/devastation-up` remains the supported convergence command.

## Image Mirrors

Docker Hub images use the Docker daemon pull-through cache automatically. Images from other registries are mirrored explicitly into the private registry before dependent services start.

Current mirrored images include Keycloak from `quay.io`, Playwright from `mcr.microsoft.com`, Jaeger from `cr.jaegertracing.io`, and cAdvisor from `gcr.io`.

Refresh the explicit mirrors:

```bash
DEVASTATION_MIRROR_FORCE=1 bin/devastation-mirror-images
```

Add new required non-Docker-Hub images to `devastation_mirrored_images` in `group_vars/all.yml`, then point Compose at the corresponding `registry.deva.station/devastation-mirror/...` tag.

## Troubleshooting

DNS not resolving:

```bash
getent hosts iam.deva.station mail.deva.station smtp.mail.deva.station keystone.deva.station s3.deva.station seaweed.deva.station
docker compose -f /srv/devastation/compose/compose.yml ps dns
```

TLS certificate not trusted:

```bash
sudo /usr/local/bin/devastation-rotate-trust-universe --verify-only
ls /usr/local/share/ca-certificates/devastation-root-ca.crt
```

Container unhealthy or not reachable:

```bash
docker compose -f /srv/devastation/compose/compose.yml ps
docker compose -f /srv/devastation/compose/compose.yml logs --tail=100 iam mail keystone seaweed app-gateway
```

S3 path-style issues: set `force_path_style`, `forcePathStyle`, or the SDK equivalent to true. The local endpoint is `https://s3.deva.station`; bucket virtual hostnames are not configured.

App cannot reach SMTP: use `smtp.mail.deva.station:1025` from the host or another container on the `devastation` network. Do not enable TLS or authentication unless you have explicitly changed Mailpit config.

OIDC redirect URI mismatch: in Keycloak, update the `devastation-demo` client redirect URI list to include the exact callback URL used by the app.
