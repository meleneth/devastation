locals {
  certificate_dir = startswith(var.certificate_dir, "/") ? var.certificate_dir : abspath("${path.module}/${var.certificate_dir}")

  apps = {
    avatars = {
      namespace      = "avatars"
      hostname       = "avatars.${var.domain}"
      ip             = "172.30.42.80"
      image          = "${var.local_registry}/meleneth/avatars"
      source_image   = "${var.source_registry}/meleneth/avatars"
      service_port   = 80
      container_port = 8080
      replicas       = 2
    }
    cnegng-docs = {
      namespace      = "default"
      hostname       = "cnegng-docs.${var.domain}"
      ip             = "172.30.42.81"
      image          = "${var.local_registry}/meleneth/cnegng-docs"
      source_image   = "${var.source_registry}/meleneth/cnegng-docs"
      service_port   = 80
      container_port = 80
      replicas       = 2
    }
    devblog = {
      namespace      = "default"
      hostname       = "devblog.${var.domain}"
      ip             = "172.30.42.82"
      image          = "${var.local_registry}/meleneth/devblog"
      source_image   = "${var.source_registry}/meleneth/devblog"
      service_port   = 80
      container_port = 80
      replicas       = 2
    }
    hiveware = {
      namespace      = "default"
      hostname       = "hiveware.${var.domain}"
      ip             = "172.30.42.83"
      image          = "${var.local_registry}/meleneth/hiveware"
      source_image   = "${var.source_registry}/meleneth/hiveware"
      service_port   = 80
      container_port = 80
      replicas       = 2
    }
    js-melstars = {
      namespace      = "js-melstars"
      hostname       = "js-melstars.${var.domain}"
      ip             = "172.30.42.84"
      image          = "${var.local_registry}/meleneth/js-melstars"
      source_image   = "${var.source_registry}/meleneth/js-melstars"
      service_port   = 80
      container_port = 80
      replicas       = 2
    }
    multifractory = {
      namespace      = "multifractory"
      hostname       = "multifractory.${var.domain}"
      ip             = "172.30.42.95"
      image          = "${var.local_registry}/devastation/multifractory"
      source_image   = "${var.local_registry}/devastation/multifractory"
      service_port   = 80
      container_port = 80
      replicas       = 2
    }
    liz = {
      namespace      = "default"
      hostname       = "liz.${var.domain}"
      ip             = "172.30.42.85"
      image          = "${var.local_registry}/meleneth/liz"
      source_image   = "${var.source_registry}/meleneth/liz"
      service_port   = 80
      container_port = 80
      replicas       = 2
    }
    login = {
      namespace      = "default"
      hostname       = "login.${var.domain}"
      ip             = "172.30.42.86"
      image          = "${var.local_registry}/devastation/login"
      source_image   = "${var.local_registry}/devastation/login"
      service_port   = 80
      container_port = 8000
      replicas       = 2
    }
    naughtsea = {
      namespace      = "naughtsea"
      hostname       = "naughtsea.${var.domain}"
      ip             = "172.30.42.87"
      image          = "${var.local_registry}/meleneth/naughtsea"
      source_image   = "${var.source_registry}/meleneth/naughtsea"
      service_port   = 80
      container_port = 8000
      replicas       = 2
    }
    pymaker = {
      namespace      = "default"
      hostname       = "pymaker.${var.domain}"
      ip             = "172.30.42.88"
      image          = "${var.local_registry}/meleneth/pymaker"
      source_image   = "${var.source_registry}/meleneth/pymaker"
      service_port   = 8000
      container_port = 8000
      replicas       = 2
    }
    rubymaker = {
      namespace      = "rubymaker"
      hostname       = "rubymaker.${var.domain}"
      ip             = "172.30.42.89"
      image          = "${var.local_registry}/meleneth/rubymaker"
      source_image   = "${var.source_registry}/meleneth/rubymaker"
      service_port   = 80
      container_port = 8000
      replicas       = 2
    }
    smlmaker = {
      namespace      = "smlmaker"
      hostname       = "smlmaker.${var.domain}"
      ip             = "172.30.42.90"
      image          = "${var.local_registry}/meleneth/smlmaker"
      source_image   = "${var.source_registry}/meleneth/smlmaker"
      service_port   = 80
      container_port = 8000
      replicas       = 2
    }
    templator = {
      namespace      = "templator"
      hostname       = "templator.${var.domain}"
      ip             = "172.30.42.91"
      image          = "${var.local_registry}/meleneth/templator"
      source_image   = "${var.source_registry}/meleneth/templator"
      service_port   = 80
      container_port = 8000
      replicas       = 2
    }
    vjn = {
      namespace      = "default"
      hostname       = "vjn.${var.domain}"
      ip             = "172.30.42.92"
      image          = "${var.local_registry}/meleneth/veronicajinthenazarenevue"
      source_image   = "${var.source_registry}/meleneth/veronicajinthenazarenevue"
      service_port   = 80
      container_port = 80
      replicas       = 2
    }
    vuemaker = {
      namespace      = "default"
      hostname       = "vuemaker.${var.domain}"
      ip             = "172.30.42.93"
      image          = "${var.local_registry}/meleneth/vuemaker"
      source_image   = "${var.source_registry}/meleneth/vuemaker"
      service_port   = 8000
      container_port = 8000
      replicas       = 2
    }
    webhaxe = {
      namespace      = "default"
      hostname       = "webhaxe.demo.${var.domain}"
      ip             = "172.30.42.94"
      image          = "${var.local_registry}/meleneth/webhaxe"
      source_image   = "${var.source_registry}/meleneth/webhaxe"
      service_port   = 80
      container_port = 80
      replicas       = 2
    }
  }

  edge_only_apps = {
    datawires = {
      namespace    = "default"
      hostname     = "datawires.${var.domain}"
      ip           = "172.30.42.96"
      service_port = 80
    }
  }

  routable_apps = merge(local.apps, local.edge_only_apps)

  app_namespaces = toset([for app in values(local.apps) : app.namespace])

  hostnames = [for app in values(local.routable_apps) : app.hostname]

  namespace_documents = [
    for namespace in local.app_namespaces : {
      apiVersion = "v1"
      kind       = "Namespace"
      metadata = {
        name = namespace
        labels = {
          "istio-injection" = "enabled"
        }
      }
    }
  ]

  gateway_documents = concat([
    {
      apiVersion = "networking.istio.io/v1"
      kind       = "Gateway"
      metadata = {
        name      = var.istio_gateway_name
        namespace = var.istio_gateway_namespace
        labels = {
          "app.kubernetes.io/part-of" = "sectorfour-mirror"
        }
      }
      spec = {
        selector = var.istio_gateway_service_selector
        servers = concat([
          {
            port = {
              number   = 80
              name     = "http"
              protocol = "HTTP"
            }
            hosts = local.hostnames
            tls   = { httpsRedirect = true }
          }
          ], [
          for name, app in local.routable_apps : {
            port = {
              number   = 443
              name     = "https-${name}"
              protocol = "HTTPS"
            }
            hosts = [app.hostname]
            tls = {
              mode           = "SIMPLE"
              credentialName = "${name}-tls"
            }
          }
        ])
      }
    }
    ], [
    for name, app in local.routable_apps : {
      apiVersion = "v1"
      kind       = "Service"
      metadata = {
        name      = "${name}-istio-edge"
        namespace = var.istio_gateway_namespace
        labels = {
          app                         = "${name}-istio-edge"
          "app.kubernetes.io/part-of" = "sectorfour-mirror"
        }
      }
      spec = {
        type           = "LoadBalancer"
        loadBalancerIP = app.ip
        selector       = var.istio_gateway_service_selector
        ports = [
          { name = "http", port = 80, targetPort = 80 },
          { name = "https", port = 443, targetPort = 443 }
        ]
      }
    }
  ])

  edge_only_documents = flatten([
    for name, app in local.edge_only_apps : [
      {
        apiVersion = "networking.istio.io/v1"
        kind       = "VirtualService"
        metadata = {
          name      = name
          namespace = app.namespace
          labels = {
            app                         = name
            "app.kubernetes.io/part-of" = "sectorfour-mirror"
          }
        }
        spec = {
          hosts    = [app.hostname]
          gateways = ["${var.istio_gateway_namespace}/${var.istio_gateway_name}"]
          http = [{
            route = [{
              destination = {
                host = "${name}.${app.namespace}.svc.cluster.local"
                port = { number = app.service_port }
              }
            }]
          }]
        }
      }
    ]
  ])

  app_documents = flatten([
    for name, app in local.apps : [
      {
        apiVersion = "apps/v1"
        kind       = "Deployment"
        metadata = {
          name      = name
          namespace = app.namespace
          labels = {
            app                         = name
            "app.kubernetes.io/part-of" = "sectorfour-mirror"
          }
        }
        spec = {
          replicas = app.replicas
          selector = { matchLabels = { app = name } }
          template = {
            metadata = {
              labels = {
                app                         = name
                "app.kubernetes.io/part-of" = "sectorfour-mirror"
              }
              annotations = {
                "sidecar.istio.io/inject" = "true"
              }
            }
            spec = {
              containers = [{
                name            = name
                image           = app.image
                imagePullPolicy = "IfNotPresent"
                ports           = [{ name = "http", containerPort = app.container_port }]
              }]
            }
          }
        }
      },
      {
        apiVersion = "v1"
        kind       = "Service"
        metadata = {
          name      = name
          namespace = app.namespace
          labels = {
            app                         = name
            "app.kubernetes.io/part-of" = "sectorfour-mirror"
          }
        }
        spec = {
          type     = "ClusterIP"
          selector = { app = name }
          ports    = [{ name = "http", port = app.service_port, targetPort = app.container_port }]
        }
      },
      {
        apiVersion = "networking.istio.io/v1"
        kind       = "VirtualService"
        metadata = {
          name      = name
          namespace = app.namespace
          labels = {
            app                         = name
            "app.kubernetes.io/part-of" = "sectorfour-mirror"
          }
        }
        spec = {
          hosts    = [app.hostname]
          gateways = ["${var.istio_gateway_namespace}/${var.istio_gateway_name}"]
          http = [{
            route = [{
              destination = {
                host = "${name}.${app.namespace}.svc.cluster.local"
                port = { number = app.service_port }
              }
            }]
          }]
        }
      }
    ]
  ])

  mirror_yaml = join("\n---\n", [for doc in concat(local.namespace_documents, local.gateway_documents, local.edge_only_documents, local.app_documents) : yamlencode(doc)])

  metallb_yaml = join("\n---\n", [
    yamlencode({
      apiVersion = "metallb.io/v1beta1"
      kind       = "IPAddressPool"
      metadata = {
        name      = var.metallb_pool_name
        namespace = "metallb-system"
      }
      spec = { addresses = var.metallb_pool_addresses }
    }),
    yamlencode({
      apiVersion = "metallb.io/v1beta1"
      kind       = "L2Advertisement"
      metadata = {
        name      = var.metallb_pool_name
        namespace = "metallb-system"
      }
      spec = { ipAddressPools = [var.metallb_pool_name] }
    })
  ])

  host_args = join(" ", [for hostname in local.hostnames : "'${hostname}'"])

  old_edge_cleanup_commands = join("\n", [
    for name, app in local.apps : "kubectl -n '${app.namespace}' delete service,deployment,configmap '${name}-edge' '${name}-edge-nginx' --ignore-not-found"
  ])

  tls_secret_commands = join("\n", concat(["set -euo pipefail"], [
    for name, app in local.routable_apps : <<-CMD
    kubectl create namespace '${app.namespace}' --dry-run=client -o yaml | kubectl apply -f -
    kubectl create namespace '${var.istio_gateway_namespace}' --dry-run=client -o yaml | kubectl apply -f -
    if sudo -n true 2>/dev/null; then
      cert_b64="$(sudo -n base64 -w0 '${local.certificate_dir}/${app.hostname}/tls.crt')"
      key_b64="$(sudo -n base64 -w0 '${local.certificate_dir}/${app.hostname}/tls.key')"
      jq -n \
        --arg name '${name}-tls' \
        --arg namespace '${app.namespace}' \
        --arg cert "$cert_b64" \
        --arg key "$key_b64" \
        '{apiVersion: "v1",
          kind: "Secret",
          metadata: {name: $name, namespace: $namespace, labels: {"app.kubernetes.io/part-of": "sectorfour-mirror"}},
          type: "kubernetes.io/tls",
          data: {"tls.crt": $cert, "tls.key": $key}}' \
        | kubectl apply -f -
      jq -n \
        --arg name '${name}-tls' \
        --arg namespace '${var.istio_gateway_namespace}' \
        --arg cert "$cert_b64" \
        --arg key "$key_b64" \
        '{apiVersion: "v1",
          kind: "Secret",
          metadata: {name: $name, namespace: $namespace, labels: {"app.kubernetes.io/part-of": "sectorfour-mirror"}},
          type: "kubernetes.io/tls",
          data: {"tls.crt": $cert, "tls.key": $key}}' \
        | kubectl apply -f -
    elif kubectl -n '${app.namespace}' get secret '${name}-tls' >/dev/null 2>&1; then
      kubectl -n '${app.namespace}' get secret '${name}-tls' -o json \
        | jq '.metadata.namespace = "${var.istio_gateway_namespace}" |
              .metadata.labels."app.kubernetes.io/part-of" = "sectorfour-mirror" |
              del(.metadata.uid,
                  .metadata.resourceVersion,
                  .metadata.creationTimestamp,
                  .metadata.managedFields,
                  .metadata.ownerReferences,
                  .metadata.annotations."kubectl.kubernetes.io/last-applied-configuration")' \
        | kubectl apply -f -
    else
      echo "No reusable ${name}-tls Secret found in ${app.namespace}; run with warm sudo so Terraform can read ${local.certificate_dir}/${app.hostname}/tls.*" >&2
      exit 1
    fi
    CMD
  ]))
}
