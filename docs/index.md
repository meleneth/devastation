# Devastation Runbook

`devastation` converges a Debian-family machine into a local development environment under the `deva.station` DNS root.

Start here after running:

```bash
./bin/devastation-up
```

The local portal is available at:

- `https://deva.station`
- `https://www.deva.station`
- `https://deva.station/docs/`
- `https://www.deva.station/docs/`

Useful defaults:

- GitLab: `https://gitlab.deva.station`
- TeamCity: `http://teamcity.deva.station:8111`
- Vault: `http://vault.deva.station:8200`
- MinIO console: `http://storage.deva.station:9001`
- IAM: `https://iam.deva.station`
- Mailpit: `https://mail.deva.station`
- Keystone: `https://keystone.deva.station`
- SeaweedFS S3: `https://s3.deva.station`
- Eventline GoAWS: `http://eventline.deva.station:4100`
- Grafana: `http://grafana.deva.station:3000`

The pages in this runbook focus on tasks a user still has to do manually: first GitLab sign-in, approving users, registering a runner, using Vault, using local AWS-style services, and wiring generated applications to shared IAM, mail, browser-test, admin/content, and object-storage services.
