locals {
  ingress_config = var.ingress_nginx.proxy_cache ? "{http-snippet: 'proxy_cache_path /tmp/nginx-cache levels=1:2 keys_zone=s3_cache:32m max_size=1g inactive=60m use_temp_path=off;'}" : "{}"
}

# deploy ingress-nginx
resource "helm_release" "ingress_nginx" {
  name             = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  version          = var.ingress_nginx.ingress_version
  create_namespace = true
  namespace        = "ingress-nginx"
  atomic           = true

  values = [
    templatefile("../../config/ingress-nginx.yaml", {
      replica_count            = var.ingress_nginx.ingress_replicas[var.environment].replica_count,
      load_balancer_ip_address = data.terraform_remote_state.vpc.outputs.load_balancer_ip_address.address,
      external_ip_addresses    = join(",", setsubtract(values(data.terraform_remote_state.vpc.outputs.external_ip_addresses)[*], [values(data.terraform_remote_state.vpc.outputs.external_ip_addresses)[0]])),
      ingress_config           = local.ingress_config
    })
  ]
}
