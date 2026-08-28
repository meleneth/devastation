# Devastation Requirements

This document defines observable behavior. Configuration examples and service
inventories describe implementation; they do not replace these requirements.

## Local package caches

### Common requirements

- Package downloads made by supported host tools and supported Docker
  containers must use the corresponding Devastation cache by default.
- "Transparent" means a project does not need cache-specific Dockerfile lines,
  repository configuration, command-line flags, or environment variables.
- Transparency must cover both `docker run` containers and Docker build steps.
- A cache miss may contact its configured upstream. A cache hit must remain
  usable when that upstream is unavailable.
- Cached artifacts must survive cache-container recreation and host reboot
  under `/srv/devastation`.
- Validation must exercise a real package download from an otherwise
  unmodified client, not merely check that the cache port is reachable.

### RubyGems — current implementation target

- Host `gem` and Bundler operations whose source is RubyGems.org must use the
  local Gemstash service without per-project configuration.
- `gem` and Bundler operations in supported Ruby containers must use Gemstash
  without modifying the project or its Dockerfile.
- The acceptance test must cover an unmodified Ruby runtime container and an
  unmodified `RUN gem fetch ...` Docker build step.
- Gem payloads must be visible in the persistent Gemstash data directory and in
  `bin/devastation-cache-stats` after the acceptance test.

Other language ecosystems will be specified and implemented separately.
