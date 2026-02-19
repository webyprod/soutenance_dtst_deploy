# 🚀 Soutenance DTST - Déploiement

Repository de déploiement pour l'application de gestion d'utilisateurs. Contient les configurations pour tous les environnements (recette, pré-production, production, infrastructure).

## 📋 Description

Ce repository centralise tous les fichiers de configuration nécessaires au déploiement de l'application sur différents environnements. Il suit une approche GitOps où chaque branche représente un environnement spécifique.

## 🌿 Branches

### 🧪 recette
**Environnement de validation fonctionnelle**

- **Plateforme** : Docker Compose sur instance Jenkins EC2
- **Déploiement** : Automatique via pipeline REC1-Deploy
- **Déclencheur** : Succès des pipelines REC1-Backend et REC1-Frontend
- **Contenu** : `docker-compose.yml`
- **Images** : Tags `latest` (webyprod/soutenance-project-demo:latest, webyprod/soutenance-ui:latest, mysql:8.0)
- **Usage** : Tests fonctionnels manuels avant release
- **Accès** : http://[jenkins-ip]

**Déploiement :**
```bash
docker compose down
docker compose pull
docker compose up -d
```

### 🔵 preprod
**Environnement de pré-production Kubernetes**

- **Plateforme** : Kubernetes EKS (namespace preprod)
- **Déploiement** : GitOps via ArgoCD
- **Déclencheur** : Pipeline DEPLOY K8S avec paramètre ENV=preprod
- **Contenu** : Helm Charts (`users-chart/`), ArgoCD Application (`argocd-apps/soutenance-preprod.yaml`)
- **Configuration** : `users-chart/values.yaml` avec tags d'images versionnés
- **Usage** : Tests finaux avant mise en production
- **Accès** : https://preprod.user-portail.ip-ddns.com
- **SSL/TLS** : Certificat AWS Certificate Manager
- **Monitoring** : Datadog actif

**ArgoCD Application :**
- Surveille la branche `preprod` de ce repository
- Synchronisation automatique des changements
- Déploiement rolling update

### 🟢 prod
**Environnement de production Kubernetes**

- **Plateforme** : Kubernetes EKS (namespace prod)
- **Déploiement** : GitOps via ArgoCD
- **Déclencheur** : Pipeline DEPLOY K8S avec paramètre ENV=prod
- **Contenu** : Helm Charts (`users-chart/`), ArgoCD Application (`argocd-apps/soutenance-prod.yaml`)
- **Configuration** : `users-chart/values.yaml` avec tags d'images versionnés
- **Usage** : Application accessible aux utilisateurs finaux
- **Accès** : https://prod.user-portail.ip-ddns.com
- **SSL/TLS** : Certificat AWS Certificate Manager
- **Monitoring** : Datadog actif
- **Alertes** : Email si pods non-Running

**ArgoCD Application :**
- Surveille la branche `prod` de ce repository
- Synchronisation automatique des changements
- Déploiement rolling update (zero downtime)

### 🏗️ infra
**Infrastructure as Code Terraform**

- **Contenu** : Fichiers Terraform (`.tf`) pour provisionner l'infrastructure AWS complète
- **Composants déployés** :
    - VPC avec 4 subnets (2 publics, 2 privés) sur 2 Availability Zones
    - Instances EC2 : Jenkins (t2.large), SonarQube (t2.medium)
    - Cluster EKS avec Node Group (3x t3.medium, autoscaling 2-4)
    - RDS MySQL (db.t3.micro, 20GB)
    - Security Groups, IAM Roles, OIDC Provider
    - Kubernetes resources (namespaces, secrets)
    - Helm releases (ArgoCD, AWS Load Balancer Controller)
- **Usage** : Déploiement et gestion de l'infrastructure

**Commandes Terraform :**
```bash
terraform init     # Initialisation
terraform plan     # Prévisualisation
terraform apply    # Déploiement infrastructure
```

**Temps de déploiement** : ~15 minutes pour l'infrastructure complète

## 📦 Structure des Branches

### Recette
```
.
├── docker-compose.yml
└── README.md
```

### Preprod / Prod
```
.
├── users-chart/
│   ├── Chart.yaml
│   ├── values.yaml          # Configuration images (tags modifiés par pipeline)
│   └── templates/
│       ├── deployment.yaml  # Deployments frontend/backend
│       ├── service.yaml     # Services Kubernetes
│       └── ingress.yaml     # Ingress avec ALB
├── argocd-apps/
│   └── soutenance-{env}.yaml  # ArgoCD Application
└── README.md
```

### Infra
```
.
├── main.tf              # Configuration principale
├── vpc.tf               # VPC et réseau
├── ec2.tf               # Instances Jenkins/SonarQube
├── eks.tf               # Cluster EKS
├── rds.tf               # Base de données MySQL
├── security.tf          # Security Groups
├── iam.tf               # Rôles et policies IAM
├── kubernetes.tf        # Resources Kubernetes
├── helm.tf              # Releases Helm
├── variables.tf         # Variables
└── outputs.tf           # Outputs
```

## 🔄 Workflow de Déploiement

### 1. Recette (Validation Fonctionnelle)
```
REC1-Backend → REC1-Frontend → REC1-Deploy
                                    ↓
                            docker-compose up
                                    ↓
                          Tests manuels sur http://[jenkins-ip]
```

### 2. Preprod/Prod (GitOps)
```
DEPLOY K8S (manuel)
    ↓
Modification values.yaml (tags: 1.1.0)
    ↓
Git push branche preprod/prod
    ↓
ArgoCD détecte changement
    ↓
Pull Helm Chart
    ↓
Apply sur EKS (rolling update)
    ↓
Application accessible https://{env}.user-portail.ip-ddns.com
```

## 🎯 Pipeline DEPLOY K8S

**Paramètres** :
- `BACK_VERSION` : Version backend (ex: 1.1.0)
- `FRONT_VERSION` : Version frontend (ex: 1.1.0)
- `ENV` : Environnement (preprod ou prod)

**Actions** :
1. Checkout branche correspondant à ENV
2. Modification `users-chart/values.yaml` :
   ```yaml
   usersBack:
     image: webyprod/soutenance-project-demo
     tag: "1.1.0"  # ← Mis à jour
   
   usersFront:
     image: webyprod/soutenance-ui
     tag: "1.1.0"  # ← Mis à jour
   ```
3. Commit : "Promote BACK=1.1.0, FRONT=1.1.0 to prod"
4. Push sur GitHub
5. ArgoCD synchronise automatiquement

## 🔐 Secrets Kubernetes

Les secrets sont créés par Terraform (branche infra) :
- `backend-db-secret` (namespaces prod et preprod)
    - SPRING_DATASOURCE_URL
    - SPRING_DATASOURCE_USERNAME
    - SPRING_DATASOURCE_PASSWORD
- `datadog-secret` (namespace datadog)
    - api-key

## 🔗 ArgoCD Applications

### Pré-production
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: soutenance-preprod
  namespace: argocd
spec:
  source:
    repoURL: https://github.com/webyprod/soutenance_dtst_deploy
    targetRevision: preprod
    path: users-chart
  destination:
    server: https://kubernetes.default.svc
    namespace: preprod
```

### Production
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: soutenance-prod
  namespace: argocd
spec:
  source:
    repoURL: https://github.com/webyprod/soutenance_dtst_deploy
    targetRevision: prod
    path: users-chart
  destination:
    server: https://kubernetes.default.svc
    namespace: prod
```

## 🛠️ Commandes Utiles

### Vérifier déploiements
```bash
# ArgoCD status
kubectl get all -n argocd

# Pods status
kubectl get pods -n prod
kubectl get pods -n preprod

# Ingress et ALB
kubectl get ingress -n prod
kubectl get ingress -n preprod
```

### Logs
```bash
# Logs application
kubectl logs <pod-name> -n prod

# Logs ArgoCD
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server
```

### Rollback
En cas de problème, modifier values.yaml avec la version précédente et pusher. ArgoCD redéploiera automatiquement.

## 🔗 Liens

- **Backend** : https://github.com/webyprod/soutenance_dtst
- **Frontend** : https://github.com/webyprod/soutenance_dtst_ui
- **Production** : https://prod.user-portail.ip-ddns.com
- **Pré-production** : https://preprod.user-portail.ip-ddns.com