output "mirror_hosts" {
  value = {
    for name, app in local.apps : name => {
      hostname = app.hostname
      ip       = app.ip
      image    = app.image
    }
  }
}

output "cluster_ca_certificate" {
  value = "/srv/devastation/ca/root-ca.crt"
}
