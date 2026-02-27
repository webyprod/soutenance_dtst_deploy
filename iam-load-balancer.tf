# Role IAM pour AWS Load Balancer Controller
# Trust via OIDC Provider du cluster EKS
# Le role peut être assumé SEULEMENT si :
# Token vient de OIDC Provider EKS (vérifié)
# Seul le Service Account 'aws-load-balancer-controller'
# dans namespace 'kube-system' peut assumer ce role.
# Aucun autre pod ne peut l'utiliser
resource "aws_iam_role" "alb_controller" {
  name = "eks-alb-controller-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.eks.arn # L'ARN de l'OIDC Provider du cluster EKS, qui fait confiance aux tokens JWT émis par ce cluster
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
          }
        }
      }
    ]
  })
}



resource "aws_iam_policy" "alb_controller_policy" {
  name   = "AWSLoadBalancerControllerIAMPolicy"
  policy = file("${path.module}/alb-policy.json")
}


# On attache au rôle IAM une policy officielle (chargée depuis un fichier JSON) 
# qui donne au contrôleur toutes les permissions nécessaires pour 
# créer, modifier et supprimer des Load Balancers, des Target Groups, des listeners, etc.
resource "aws_iam_role_policy_attachment" "alb_controller_attach" {
  role       = aws_iam_role.alb_controller.name
  policy_arn = aws_iam_policy.alb_controller_policy.arn
}



# On crée un service account dans le namespace kube-system, nommé aws-load-balancer-controller.
# Ce service account contient une annotation spéciale :
# eks.amazonaws.com/role-arn = <ARN du rôle IAM>.
# Tout pod qui utilise ce service account doit recevoir les permissions du rôle IAM associé
resource "kubernetes_service_account_v1" "alb_controller_sa" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"

    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.alb_controller.arn
    }
  }
}

# On installe le chart Helm officiel du contrôleur
# On configure le chart pour utiliser le service account que nous avons créé
# Le contrôleur va maintenant pouvoir assumer le rôle IAM et obtenir les permissions nécessaires pour gérer les Load Balancers
# les pods du Load Balancer Controller utiliseront automatiquement le service account annoté, et donc assumeront le rôle IAM
resource "helm_release" "aws_lb_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.7.1"

  values = [
    yamlencode({
      clusterName = aws_eks_cluster.cluster.name
      region      = "us-east-1"
      vpcId       = aws_vpc.main.id
      serviceAccount = {
        create = false
        name   = "aws-load-balancer-controller"
      }
    })
  ]

  depends_on = [
    kubernetes_service_account_v1.alb_controller_sa
  ]
}
