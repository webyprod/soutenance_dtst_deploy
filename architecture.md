
**Ressources AWS:**

*   **VPC:**
    *   `aws_vpc.main` (10.0.0.0/16)
    *   Sous-réseaux publics: `aws_subnet.public_a` (us-east-1a, 10.0.1.0/24), `aws_subnet.public_b` (us-east-1b, 10.0.2.0/24)
    *   Sous-réseaux privés: `aws_subnet.private_a` (us-east-1a, 10.0.3.0/24), `aws_subnet.private_b` (us-east-1b, 10.0.4.0/24)
    *   Passerelle Internet: `aws_internet_gateway.igw`
    *   Tables de routage: `aws_route_table.public_rt` (associée aux sous-réseaux publics)
*   **EKS:**
    *   Cluster EKS: `aws_eks_cluster.cluster` (clustersoutenance, version 1.30)
    *   Groupe de nœuds: `aws_eks_node_group.nodegroup` (t3.medium, 2-4 instances)
    *   Rôles IAM: `aws_iam_role.eks_cluster_role`, `aws_iam_role.eks_node_role`, `aws_iam_role.jenkins_role`
    *   Profil d'instance: `aws_iam_instance_profile.jenkins_profile`
*   **EC2:**
    *   Instances: `aws_instance.jenkins` (t2.large, public), `aws_instance.nexus_sonar` (t2.medium, public)
    *   Groupes de sécurité: `aws_security_group.main_sg`, `aws_security_group.rds_sg`
*   **RDS:**
    *   Groupe de sous-réseaux: `aws_db_subnet_group.db_subnets`
    *   Instance MySQL: `aws_db_instance.mysql` (db.t3.micro)
*   **Autres:**
    *   Données: `data.aws_ami.ubuntu`, `data.aws_eks_cluster.cluster`, `data.aws_eks_cluster_auth.cluster`
    *   Helm: `helm_release.argocd`
    *   Kubernetes: `kubernetes_namespace.prod`, `kubernetes_namespace.preprod`, `kubernetes_namespace.argocd`, `kubernetes_secret.backend_db`, `kubernetes_secret.backend_db_preprod`

**Interconnexions:**

*   Le VPC est connecté à la passerelle Internet.
*   Les sous-réseaux publics sont associés à la table de routage publique, qui a une route vers la passerelle Internet.
*   Le cluster EKS est déployé dans les sous-réseaux publics et privés.
*   Les instances EC2 sont déployées dans les sous-réseaux publics et utilisent le groupe de sécurité `main_sg`.
*   L'instance RDS est déployée dans les sous-réseaux privés et utilise le groupe de sécurité `rds_sg`.
*   Les instances EC2 et le cluster EKS peuvent accéder à l'instance RDS via le groupe de sécurité `rds_sg`.
*   Helm est utilisé pour déployer ArgoCD dans le cluster EKS.
*   Les secrets Kubernetes sont créés pour accéder à la base de données MySQL.

**Remarques:**

*   Le diagramme montre une architecture typique avec un VPC, des sous-réseaux publics et privés, un cluster EKS, des instances EC2, une base de données RDS et ArgoCD pour la gestion des applications.
*   Les groupes de sécurité contrôlent le trafic réseau vers et depuis les ressources.
*   Les rôles IAM définissent les permissions des ressources AWS.
*   Les secrets Kubernetes stockent les informations sensibles.
