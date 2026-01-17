« Je vais vous présenter l’architecture DevOps que j’ai mise en place, entièrement déployée avec Terraform sur AWS. »

🌐 1. Vue globale

L’infrastructure est hébergée sur AWS, dans la région us-east-1, et repose sur un VPC unique en 10.0.0.0/16.
Ce VPC est découpé en subnets publics et privés, répartis sur deux zones de disponibilité, afin d’assurer la haute disponibilité.

🌐 2. Architecture réseau

Les subnets publics hébergent :

les outils DevOps (Jenkins, Nexus, SonarQube)

les nœuds du cluster Kubernetes (EKS)

Les subnets privés hébergent la base de données MySQL RDS, qui n’est pas exposée à Internet.

L’accès Internet est assuré via une Internet Gateway, et le trafic est contrôlé par des Security Groups.

🔧 3. Chaîne DevOps & CI/CD

Jenkins (EC2) :

orchestre les pipelines CI/CD

construit les applications

déclenche les déploiements sur Kubernetes

SonarQube :

analyse la qualité et la dette technique

Nexus :

stocke les artefacts générés

Jenkins dispose d’un rôle IAM lui permettant d’interagir avec AWS et EKS.

☸️ 4. Kubernetes & GitOps

Les applications sont déployées sur un cluster Amazon EKS

Le cluster contient plusieurs namespaces :

prod

preprod

argocd

ArgoCD, déployé via Helm, permet une approche GitOps :

l’état du cluster est synchronisé automatiquement avec les dépôts Git

les déploiements sont traçables, reproductibles et versionnés

🗄️ 5. Base de données

Une base RDS MySQL est déployée en subnet privé

Elle est accessible uniquement depuis le cluster EKS

Les identifiants sont injectés dans les applications via des Secrets Kubernetes, différents pour prod et preprod

🔐 6. Sécurité

Séparation réseau public / privé

Accès DB restreint via Security Groups

Gestion des accès AWS via IAM

Aucun accès direct Internet vers la base de données

✅ 7. Conclusion

« Cette architecture permet de répondre aux enjeux DevOps modernes : automatisation, scalabilité, sécurité et traçabilité, tout en restant cohérente avec les bonnes pratiques cloud et Kubernetes. »