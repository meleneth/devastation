# Cluster Projects

Cluster project deploys should be command-owned, not memory-owned. The current
implementation is Terraform plus local scripts because Argo CD is installed but
does not yet own these application manifests.

## Static Project Contract

For a static project, the LLM or maintainer should create:

- `cluster/PROJECT/Dockerfile`
- `cluster/PROJECT/index.html` or whatever the Dockerfile needs
- one app entry in `cluster/terraform/locals.tf`
- one DNS/cert entry in `cluster/devastation-register-main-script-inputs`

The deploy command owns the repeated loop:

```bash
bin/devastation-deploy-cluster-project PROJECT
```

For `multifractory`:

```bash
bin/devastation-deploy-cluster-project multifractory
```

That command builds and pushes
`registry.deva.station/devastation/PROJECT:latest`, regenerates
`cluster/devastation-local-vars.yml`, runs the main bootstrap so DNS and certs
exist, applies `cluster/terraform`, and verifies rollout, DNS, and HTTPS.

## Go-Forward Setup

The near-term source of truth is still the ignored `cluster/` workspace because
this repo intentionally keeps cluster-specific state out of tracked generic
bootstrap. New projects should be implemented by updating the static project
contract above, then running the deploy command.

The next ownership step is to move app manifests into Argo CD applications.
When that happens, keep the same outer contract:

- build and push the image locally
- register DNS and cert inputs
- let the cluster controller reconcile manifests
- verify rollout, DNS, and HTTPS from one command

The command surface should remain
`bin/devastation-deploy-cluster-project PROJECT` so the LLM can implement
project changes and then run the same closed loop without asking a human to
remember operational steps.
