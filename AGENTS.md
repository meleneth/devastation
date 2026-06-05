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
