# Local Cluster Terraform

This legacy mirror configuration is now tracked along with its deployment and
storage helpers. Generated state, snapshots, and `cluster/devastation-local-vars.yml`
remain ignored.

Production application workloads are managed by the sibling `cluster-ops`
repository. Use its Terraform configuration and `bin/redeploy-deva-service` for
application changes. Do not apply this legacy mirror over those managed workloads: it
contains older application definitions and would overwrite current routing, SSO,
and storage settings. The flow below documents the legacy mirror only.

`cluster/devastation-register-main-script-inputs` remains the active source for
bootstrap DNS, certificates, and the Rubellum host mount.

## Flow

1. Build and push the local static multifractory image:

```bash
docker build -t registry.deva.station/devastation/multifractory ../multifractory
docker push registry.deva.station/devastation/multifractory
```

2. Populate the local image registry:

```bash
../devastation-populate-cluster-registry
```

3. Register DNS and TLS names with the main devastation bootstrap/CA flow:

```bash
../devastation-register-main-script-inputs
```

Then rerun the main bootstrap or trust rotation from the repo root so
`cluster/devastation-local-vars.yml` is loaded and the app hostnames are added
to DNS, `/etc/hosts`, validation, and the signed local certificate universe.

4. Deploy the local mirror:

```bash
../devastation-deploy-local-cluster
```

Terraform reads the main devastation certificates from
`/srv/devastation/certs/<hostname>/tls.*`, configures the bootstrap-managed MetalLB pool, creates the app
workloads, enables Istio sidecar injection for app pods, creates Istio
Gateway/VirtualService routing, and assigns the app IPs
`172.30.42.80-172.30.42.98` to MetalLB services that target the shared Istio
ingress gateway.

The pool is `devastation-edge`, matching the main bootstrap. MetalLB controller
installation remains owned by bootstrap; `install_metallb=true` is only for a
standalone cluster without that installation.

The deploy helper refreshes sudo before Terraform runs because the TLS private
keys are intentionally root-owned. Terraform uses non-interactive sudo only to
base64-read those cert files, then applies the Kubernetes Secret manifests with
your normal kubeconfig.

Preview with:

```bash
~/.tfenv/bin/terraform plan
```

The main devastation CA certificate path is printed as the
`cluster_ca_certificate` output.

## Rubellum

Rubellum uses `https://rubellum.deva.station` at `172.30.42.98`, namespace
`rubellum`, and the existing image
`registry.deva.station/meleneth/rubellum:393e3a15e1d2`. The image is already built
locally; publish it before deploying. Override `rubellum_image_tag` deliberately
when changing appliance versions.

The deployment runs one application container on port 3000, plus the standard
Istio sidecar. Data lives on the **host** at `/srv/devastation/storage/rubellum`.
KIND bind-mounts that directory at `/var/local/rubellum` inside the control-plane
node. A static local PV named `rubellum-data`, with reclaim policy `Retain`,
binds to the explicitly named PVC and mounts at `/data` in the appliance.
There is no dynamic provisioner or node-container storage fallback. The 20Gi
capacity is Kubernetes accounting, not a disk quota; the directory uses host
filesystem space. `Recreate` prevents overlapping
appliances during rollout. Startup and readiness probe `/up`; shutdown allows
30 seconds for the bundled services. `RUBELLUM_HOST` permits the external hostname.

The generated `kind_extra_mounts` entry is read by the main bootstrap, which
creates the host directory if absent and writes it into the KIND configuration.
Bootstrap preserves existing data-directory ownership. An existing KIND node
cannot acquire a Docker bind mount in place: after generating the new config,
recreate KIND once to activate it. Do that as a deliberate cluster reset, after
handling any other workloads that currently use disposable node storage.
The deployment checks the actual Docker bind mount and refuses to start Rubellum
if it is missing. Applying an unmounted local PV also cannot create its directory.

From the devastation repository root:

```bash
docker push registry.deva.station/meleneth/rubellum:393e3a15e1d2
cluster/devastation-register-main-script-inputs
bin/devastation-up
cluster/devastation-deploy-local-cluster
kubectl -n rubellum rollout status deployment/rubellum --timeout=300s
kubectl -n rubellum get pvc rubellum-data
getent hosts rubellum.deva.station
curl --fail --show-error https://rubellum.deva.station/up
```

Bootstrap must run before Terraform so DNS and signed certificates exist.
Terraform installs `rubellum-tls` in both `rubellum` and `istio-system`, and creates
the edge LoadBalancer, Gateway host and VirtualService. The static-project helper
does not apply to this externally built appliance image.

### Rebuilding KIND

Once the host mount has been configured, the normal rebuild sequence is:

```bash
bin/devastation-kind-reset
bin/devastation-up
cluster/devastation-deploy-local-cluster
```

The reset recreates Kubernetes objects, not `/srv/devastation/storage/rubellum`.
The new node mounts the same directory, and Terraform recreates the PV/PVC bound
to that path. The deploy helper explicitly reruns its Kubernetes provisioners on
every deployment because Terraform's `terraform_data` state cannot detect a
cluster reset. Reuse the same appliance image to reopen the existing database.

Deleting a PVC or namespace also retains host data. In the same cluster a
retained PV can remain `Released` with the old claim UID. After ensuring the old
appliance has stopped, clear that stale claim with
`kubectl patch pv rubellum-data --type=merge -p '{"spec":{"claimRef":null}}'`,
then rerun deployment to bind the new PVC. A fresh cluster has no stale claim.

Host-directory deletion or host disk failure can still lose data; the mount is
not a backup. Rubellum's coordinated whole-instance backup/restore and
cross-version upgrades are not yet supported.

### Persistence verification

Run `cluster/terraform/scripts/test-rubellum-reset` from the repository root.
It uses a separate kubeconfig, a uniquely named disposable KIND cluster and
temporary host data. It renders the production mount template and Terraform
PV/PVC/deployment, boots the cached Rubellum image, writes PostgreSQL and Redis
values, deletes the cluster while the appliance runs, then recreates it with
the same host directory. It verifies both values and the persisted instance
secret, removes the test cluster, and prints the retained test artifact path.
It never resets the main cluster.

Verified on 2026-09-28: the full reset test passed; Terraform validation and
planning, Kubernetes server dry-run of the retained PV/PVC, and the missing-mount
deployment rejection also passed. Production mount activation was completed on 2026-09-28 through bootstrap and
a deliberate KIND recreation; the live application is managed by `cluster-ops`.
