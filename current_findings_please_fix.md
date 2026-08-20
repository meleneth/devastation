# Resolved finding: Devastation DNS forwarding failure

Date observed: 2026-08-16
Date repaired: 2026-08-16

## Resolution

Upstream DNS is now discovered during convergence from active NetworkManager
devices, with `/etc/resolv.conf` as a fallback. On the affected host that selects
the reachable LAN resolver at `192.168.12.1`. An explicit
`dns_upstream_resolvers` list still overrides discovery. Loopback addresses and
CoreDNS's own `172.30.42.10` address are rejected to prevent forwarding loops.

The source repair is in `group_vars/all.yml`. Reconverge Devastation to render
the updated `/srv/devastation/dns/Corefile` and dependent cache configuration,
then run the validation checks below.

## Summary

The Devastation DNS architecture is intentional and its local authoritative layer is working. Docker containers are configured to use CoreDNS at `172.30.42.10`. CoreDNS authoritatively resolves `deva.station` and redirects selected Debian/Ubuntu repository names to the transparent apt cache.

The failure is CoreDNS's upstream forwarding path. Its generated Corefile forwards all other queries directly to `1.1.1.1` and `9.9.9.9`, but outbound DNS to those resolvers times out from the Devastation Docker network. The LAN resolver at `192.168.12.1` works from that same network.

This caused a VS Code devcontainer build to fail while installing `docker-outside-of-docker`, when `curl` could not resolve `packages.microsoft.com`.

Do not remove Docker's `172.30.42.10` DNS setting: that would bypass the intended local authoritative and cache-interception layer.

## Verified failure topology

```text
Docker containers
  -> CoreDNS 172.30.42.10
     -> authoritative deva.station records
     -> Debian/Ubuntu repository overrides -> 172.30.42.45
     -> remaining queries -> 1.1.1.1 / 9.9.9.9
```

- Docker daemon configuration: `/etc/docker/daemon.json`
- Generated CoreDNS configuration: `/srv/devastation/dns/Corefile`
- Source DNS variables: `group_vars/all.yml`
- CoreDNS template: `templates/Corefile.j2`
- Compose template: `templates/compose.yml.j2`

## Evidence

CoreDNS is running and attached to the expected address:

```text
compose-dns-1   Up 18 hours   devastation
IPv4Address: 172.30.42.10/24
```

It answers local authoritative records successfully. Its logs show upstream failures:

```text
plugin/errors: 2 . NS: read udp 172.30.42.10:42900->1.1.1.1:53: i/o timeout
plugin/errors: 2 beacons.gvt2.com. AAAA: read udp 172.30.42.10:39687->9.9.9.9:53: i/o timeout
```

Live comparison from the `devastation` bridge:

- Querying through `192.168.12.1` resolves `packages.microsoft.com`.
- Querying through `1.1.1.1` does not resolve it.
- The host itself uses `192.168.12.1` through NetworkManager and resolves normally.

The failing source configuration was:

```yaml
dns_upstream_resolvers:
  - 1.1.1.1
  - 9.9.9.9
```

## Reproduction commands

```sh
docker compose -f /srv/devastation/compose/compose.yml ps dns
docker compose -f /srv/devastation/compose/compose.yml logs --tail=120 dns

docker run --rm --network devastation --dns 192.168.12.1 \
  mcr.microsoft.com/devcontainers/javascript-node:1-20-bullseye \
  getent ahosts packages.microsoft.com

docker run --rm --network devastation --dns 1.1.1.1 \
  mcr.microsoft.com/devcontainers/javascript-node:1-20-bullseye \
  getent ahosts packages.microsoft.com
```

## Applied repair

The default is automatic discovery, while an explicit list remains supported:

```yaml
dns_upstream_resolvers:
  - 192.168.12.1 # optional override
```

Reconverge Devastation so `/srv/devastation/dns/Corefile` and dependent service configuration are regenerated and CoreDNS is reloaded/recreated. Validate both ordinary external resolution and the deliberate local overrides afterward.

This avoids assuming direct outbound UDP/53 access to public resolvers while
preserving an explicit variable override and preventing CoreDNS from forwarding
back to itself through Docker's daemon-level DNS configuration.

Relevant validation should cover:

1. `deva.station` authoritative records still resolve to `172.30.42.x` addresses.
2. Debian/Ubuntu repository names still resolve to `172.30.42.45` when transparent apt caching is enabled.
3. An unrelated external name such as `packages.microsoft.com` resolves from a default Docker container.
4. The `docker-outside-of-docker` devcontainer feature can install successfully.
5. Cache services that consume `dns_upstream_resolvers` directly still resolve their upstreams.

## Worktree note

At repair time this repository already had unrelated KMS console work, including modifications to `group_vars/all.yml`, plus other modified and untracked files. Those changes were preserved.
