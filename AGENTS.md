# Local Package Caches

This repository is designed to run inside the `devastation` local environment. Prefer the local package caches below before reaching out to public registries.

## Registry Endpoints

- Debian/Ubuntu apt proxy: `http://apt-cache.deva.station:3142`
- Docker Hub pull-through cache: `registry-cache.deva.station:5000`
- Local Docker registry: `registry.deva.station`
- npm registry: `http://npm-cache.deva.station:4873`
- Python package index: `http://pypi-cache.deva.station:3141/root/pypi/+simple/`
- RubyGems source: `http://gem-cache.deva.station:9292`

## Client Configuration

Use these settings when installing dependencies:

```bash
npm config set registry http://npm-cache.deva.station:4873
python3 -m pip config set global.index-url http://pypi-cache.deva.station:3141/root/pypi/+simple/
bundle config set mirror.https://rubygems.org http://gem-cache.deva.station:9292
gem sources --add http://gem-cache.deva.station:9292 --remove https://rubygems.org/
```

For Dockerfiles that run apt:

```dockerfile
RUN printf 'Acquire::http::Proxy "http://apt-cache.deva.station:3142";\nAcquire::https::Proxy "DIRECT";\n' \
  > /etc/apt/apt.conf.d/01devastation-proxy
```

For one-off installs:

```bash
NPM_CONFIG_REGISTRY=http://npm-cache.deva.station:4873 npm install
PIP_INDEX_URL=http://pypi-cache.deva.station:3141/root/pypi/+simple/ pip install -r requirements.txt
bundle config set --local mirror.https://rubygems.org http://gem-cache.deva.station:9292 && bundle install
gem install rake --source http://gem-cache.deva.station:9292
```

The caches are transparent proxies. They still need upstream internet the first time a package is fetched, then serve cached artifacts from `/srv/devastation` on later runs.

# Cluster App Hostnames And Certs

For new `*.deva.station` apps that are exposed through the KIND/Istio edge,
`cluster/devastation-register-main-script-inputs` is the generated handoff into
the local DNS and certificate universe. Make sure it includes the hostname, the
intended `172.30.42.x` address, and the `ca_extra_leaf_certificates` entry before
running bootstrap or trust rotation.

The cluster side still needs matching routing:

- MetalLB `IPAddressPool` must include the chosen `172.30.42.x` address.
- An `istio-system/APP-istio-edge` LoadBalancer Service must exist for that IP.
- Gateway `istio-system/sectorfour-mirror` must include the host on HTTP and a
  HTTPS server using `credentialName: APP-tls`.
- `bin/devastation-up` syncs `ca_extra_leaf_certificates` from
  `/srv/devastation/certs/HOSTNAME/` into Kubernetes as `APP-tls` in
  `istio-system` after KIND/Istio convergence. Keep app-namespace copies in the
  app Terraform/import flow when matching the existing service pattern.
