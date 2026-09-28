variable "rubellum_image_tag" {
  description = "Published Rubellum image tag; change deliberately for appliance upgrades."
  type        = string
  default     = "393e3a15e1d2"
}

variable "rubellum_storage_size" {
  description = "Advertised capacity of the static host-directory PV, not a filesystem quota."
  type        = string
  default     = "20Gi"
}

variable "rubellum_host_path" {
  description = "Host directory bind-mounted into KIND; must match kind_extra_mounts."
  type        = string
  default     = "/srv/devastation/storage/rubellum"
}

variable "rubellum_node_path" {
  description = "Mount destination inside the KIND node; must match kind_extra_mounts."
  type        = string
  default     = "/var/local/rubellum"
}

variable "rubellum_node_name" {
  description = "KIND node with the persistent host bind mount."
  type        = string
  default     = "devastation-control-plane"
}

locals {
  storage_documents = [{
    apiVersion = "v1"
    kind       = "PersistentVolume"
    metadata   = { name = "rubellum-data" }
    spec = {
      capacity                      = { storage = var.rubellum_storage_size }
      accessModes                   = ["ReadWriteOnce"]
      persistentVolumeReclaimPolicy = "Retain"
      storageClassName              = ""
      volumeMode                    = "Filesystem"
      local                         = { path = var.rubellum_node_path }
      claimRef = {
        name      = "rubellum-data"
        namespace = local.apps.rubellum.namespace
      }
      nodeAffinity = {
        required = {
          nodeSelectorTerms = [{
            matchExpressions = [{
              key      = "kubernetes.io/hostname"
              operator = "In"
              values   = [var.rubellum_node_name]
            }]
          }]
        }
      }
    }
    }, {
    apiVersion = "v1"
    kind       = "PersistentVolumeClaim"
    metadata = {
      name      = "rubellum-data"
      namespace = local.apps.rubellum.namespace
      labels = {
        app                         = "rubellum"
        "app.kubernetes.io/part-of" = "sectorfour-mirror"
      }
    }
    spec = {
      accessModes      = ["ReadWriteOnce"]
      storageClassName = ""
      volumeName       = "rubellum-data"
      resources        = { requests = { storage = var.rubellum_storage_size } }
    }
  }]

  rubellum_storage_check = "'${path.module}/scripts/check-rubellum-storage' '${var.rubellum_node_name}' '${var.rubellum_host_path}' '${var.rubellum_node_path}'"

  app_deployment_overrides = {
    rubellum = {
      # PostgreSQL and the other bundled services share a single data directory.
      strategy = { type = "Recreate" }
    }
  }

  app_pod_overrides = {
    rubellum = {
      terminationGracePeriodSeconds = 30
      volumes = [{
        name                  = "data"
        persistentVolumeClaim = { claimName = "rubellum-data" }
      }]
    }
  }

  app_container_overrides = {
    rubellum = {
      env          = [{ name = "RUBELLUM_HOST", value = local.apps.rubellum.hostname }]
      volumeMounts = [{ name = "data", mountPath = "/data" }]
      startupProbe = {
        httpGet = {
          path        = "/up"
          port        = "http"
          httpHeaders = [{ name = "Host", value = local.apps.rubellum.hostname }]
        }
        periodSeconds    = 5
        timeoutSeconds   = 5
        failureThreshold = 60
      }
      readinessProbe = {
        httpGet = {
          path        = "/up"
          port        = "http"
          httpHeaders = [{ name = "Host", value = local.apps.rubellum.hostname }]
        }
        periodSeconds    = 10
        timeoutSeconds   = 5
        failureThreshold = 3
      }
    }
  }
}
