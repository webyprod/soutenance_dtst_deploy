
# Installe ArgoCD version 7.7.5 dans namespace argocd
# Utilise configuration depuis fichier argocd-values.yaml
# Attend maximum 15 minutes que pods soient prêts
# Si échec, supprime tout (rollback)
# Installe SEULEMENT APRÈS :
## Nodes prêts
## Namespace 'argocd' existe
## AWS Load Balancer Controller est installe
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

  timeout = 900        # 15 minutes
  wait    = true       # attendre les pods
  atomic  = true       # rollback si vrai échec

  depends_on = [
  aws_eks_node_group.nodegroup,
  kubernetes_namespace.argocd,
  helm_release.aws_lb_controller
]
}
