# Cree un role pour le service EKS d'AWS.
# Quand EKS emprunte ce role, il obtient des permissions temporaires.
resource "aws_iam_role" "eks_cluster_role" {
  name = "eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "eks.amazonaws.com" },
      Action = "sts:AssumeRole"
    }]
  })
}


# Attache la policy AmazonEKSClusterPolicy au rôle eks-cluster-role
# Maintenant le role a les permissions pour gérer un cluster EKS
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# Crée un cluster EKS nommé clustersoutenance
# utilise le role eks-cluster-role pour ses permissions
# Version Kubernetes : 1.30
# déployé dans 4 subnets (2 publics + 2 privés, 2 AZ)
# API Kubernetes est accessible depuis Internet (kubectl fonctionne)
resource "aws_eks_cluster" "cluster" {
  name     = "clustersoutenance"
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = "1.30"

  vpc_config {
    subnet_ids = [
      aws_subnet.public_a.id,
      aws_subnet.public_b.id,
      aws_subnet.private_a.id,
      aws_subnet.private_b.id
    ]
    endpoint_public_access = true
  }
}


# Cree un role pour instances EC2 (qui seront utilisées comme nodes dans le cluster EKS)
# Les instances EC2 (nodes) peuvent utiliser ce role pour obtenir des permissions temporaires
resource "aws_iam_role" "eks_node_role" {
  name = "eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "ec2.amazonaws.com" },
      Action = "sts:AssumeRole"
    }]
  })
}


# Attache la policy AmazonEKSWorkerNodePolicy au rôle eks-node-role
# Maintenant le role a les permissions pour gérer communiquer avec le cluster EKS en tant que worker node
# s'enregistrer auprès du cluster, recevoir ordres, envoyer status
resource "aws_iam_role_policy_attachment" "node_AmazonEKSWorkerNodePolicy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

# Attache la policy AmazonEC2ContainerRegistryReadOnly au rôle eks-node-role
# Maintenant le role a les permissions pour accéder à ECR (registry de conteneurs)
resource "aws_iam_role_policy_attachment" "node_AmazonEC2ContainerRegistryReadOnly" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# Attache la policy AmazonEKS_CNI_Policy au rôle eks-node-role
# Maintenant le role a les permissions pour Gérer networking pods dans le cluster EKS
# Assigner IPs privées VPC aux pods, créer ENI (interfaces réseau)
resource "aws_iam_role_policy_attachment" "node_AmazonEKS_CNI_Policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}


# Cree un groupe de 3 worker nodes dans le cluster clustersoutenance
# Nodes utilisent le role eks-node-role pour permissions
# Nodes lances dans subnets publics (us-east-1a et us-east-1b) presents dans 2 AZ différentes
# Type instance : t3.medium (2 vCPU, 4 GB RAM).
# Disque : 20 GB par node.
# Scaling : min 2, max 4 nodes
# Acces SSH possible avec clé awskey
resource "aws_eks_node_group" "nodegroup" {
  cluster_name    = aws_eks_cluster.cluster.name
  node_group_name = "node2"
  node_role_arn   = aws_iam_role.eks_node_role.arn

  subnet_ids = [
    aws_subnet.public_a.id,
    aws_subnet.public_b.id
  ]

  scaling_config {
    desired_size = 3
    min_size     = 2
    max_size     = 4
  }

  instance_types = ["t3.medium"]
  disk_size      = 20

  remote_access {
    ec2_ssh_key = "awskey"
  }
}

# Enregistre le cluster EKS dans AWS IAM comme OIDC Provider
# AWS fait maintenant confiance aux tokens JWT émis par ce cluster
# Cela permet aux pods Kubernetes d'assumer des IAM roles (IRSA)
resource "aws_iam_openid_connect_provider" "eks" {
  url = aws_eks_cluster.cluster.identity[0].oidc[0].issuer

  client_id_list = [
    "sts.amazonaws.com"
  ]

  thumbprint_list = [
    "9e99a48a9960b14926bb7f3b02e22da0afd29a57"
  ]
}