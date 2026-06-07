# TeamCity

TeamCity runs at:

```bash
http://teamcity.deva.station:8111
```

The server persists data under:

```bash
/srv/devastation/teamcity
```

## First-Run Setup

1. Open `http://teamcity.deva.station:8111`.
2. Follow the TeamCity first-start wizard.
3. Create the first administrator account.
4. Use the internal URL `http://teamcity.deva.station:8111` when TeamCity asks for its server URL.

## Local Registry

Use the local Docker registry for build images:

```bash
dpush my-image:dev
```

That pushes `registry.deva.station/my-image:dev`.

## GitLab

Use `https://gitlab.deva.station` as the GitLab server URL from TeamCity. The local root CA is installed on the host and in the service trust flow, but TeamCity may still ask you to confirm or configure trust depending on the integration path you choose.
