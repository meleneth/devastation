variable "domain" {
  type    = string
  default = "deva.station"
}

variable "default_namespace" {
  type    = string
  default = "default"
}

variable "local_registry" {
  type    = string
  default = "registry.deva.station"
}

variable "source_registry" {
  type    = string
  default = "registry.sectorfour"
}

variable "istio_gateway_namespace" {
  type    = string
  default = "istio-system"
}

variable "istio_gateway_name" {
  type    = string
  default = "sectorfour-mirror"
}

variable "istio_gateway_service_selector" {
  type = map(string)
  default = {
    app   = "istio-ingressgateway"
    istio = "ingressgateway"
  }
}

variable "metallb_manifest_url" {
  type    = string
  default = "https://raw.githubusercontent.com/metallb/metallb/v0.14.9/config/manifests/metallb-native.yaml"
}

variable "install_metallb" {
  description = "Install the legacy standalone controller only when bootstrap does not already manage MetalLB."
  type        = bool
  default     = false
}

variable "metallb_pool_name" {
  type    = string
  default = "devastation-edge"
}

variable "metallb_pool_addresses" {
  type    = list(string)
  default = ["172.30.42.80-172.30.42.85", "172.30.42.87-172.30.42.98"]
}

variable "certificate_dir" {
  type    = string
  default = "/srv/devastation/certs"
}
