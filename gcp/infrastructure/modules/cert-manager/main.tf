# deploy cert-manager
resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io/"
  chart            = "cert-manager"
  version          = var.cert_manager.cert_manager_version
  create_namespace = true
  namespace        = "cert-manager"
  atomic           = true

  set {
    name  = "installCRDs"
    value = "true"
  }
}

# deploy cluster-issuer
resource "kubectl_manifest" "cluster_issuer" {
  yaml_body = file("../../config/cluster-issuer.yaml")
}
