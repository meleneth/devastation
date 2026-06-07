# Vault

Vault runs in dev mode at:

```bash
http://vault.deva.station:8200
```

The shell profile created by `user_setup` exports:

```bash
VAULT_ADDR=http://vault.deva.station:8200
VAULT_TOKEN=devastation
```

The host also installs the Vault CLI that matches the configured Vault server version.

## Quick Check

Open a new shell after bootstrap, then run:

```bash
vault status
vault token lookup
```

## Store And Read A Secret

Enable a local KV store:

```bash
vault secrets enable -path=dev kv-v2
```

Write a secret:

```bash
vault kv put dev/example username=devastation password=devastation
```

Read it:

```bash
vault kv get dev/example
```

Read one field:

```bash
vault kv get -field=password dev/example
```

## What To Remember

This is a local dev Vault. The root token is intentionally simple and documented. Do not treat it as production-grade secret storage without changing the token, persistence, policies, and unseal model.
