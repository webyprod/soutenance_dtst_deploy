resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "7.7.5" # version stable au moment où j'écris

  namespace        = kubernetes_namespace.argocd.metadata[0].name
  create_namespace = false

  values = [
    file("${path.module}/argocd-values.yaml")
  ]
}
