resource "terraform_data" "metallb" {
  input = {
    manifest_url = var.metallb_manifest_url
    pool_yaml    = local.metallb_yaml
  }

  triggers_replace = {
    pool_hash = sha256(local.metallb_yaml)
  }

  provisioner "local-exec" {
    command     = <<-EOT
      set -euo pipefail
      %{if var.install_metallb}
      kubectl apply -f '${var.metallb_manifest_url}'
      kubectl wait --for=condition=Established crd/ipaddresspools.metallb.io --timeout=120s
      kubectl wait --for=condition=Established crd/l2advertisements.metallb.io --timeout=120s
      kubectl -n metallb-system rollout status deployment/controller --timeout=300s
      kubectl -n metallb-system rollout status daemonset/speaker --timeout=300s
      %{endif}
      kubectl apply -f - <<'YAML'
      ${local.metallb_yaml}
      YAML
    EOT
    interpreter = ["/bin/bash", "-c"]
  }
}

resource "terraform_data" "tls_secrets" {
  input = {
    certificate_dir = local.certificate_dir
    apps            = local.apps
  }

  triggers_replace = {
    command_hash = sha256(local.tls_secret_commands)
  }

  provisioner "local-exec" {
    command     = local.tls_secret_commands
    interpreter = ["/bin/bash", "-c"]
  }
}

resource "terraform_data" "apps" {
  depends_on = [
    terraform_data.metallb,
    terraform_data.tls_secrets
  ]

  input = {
    apps = local.apps
  }

  triggers_replace = {
    manifest_hash = sha256(local.mirror_yaml)
  }

  provisioner "local-exec" {
    command     = <<-EOT
      set -euo pipefail
      ${local.rubellum_storage_check}
      ${local.old_edge_cleanup_commands}
      kubectl apply -f - <<'YAML'
      ${local.mirror_yaml}
      YAML
    EOT
    interpreter = ["/bin/bash", "-c"]
  }
}
