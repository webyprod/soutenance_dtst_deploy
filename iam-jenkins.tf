# Cree un role pour instances EC2 (qui seront utilisées pour héberger Jenkins)
# Les instances EC2 peuvent utiliser ce role pour obtenir des permissions temporaires
resource "aws_iam_role" "jenkins_role" {
  name = "jenkins-eks-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}


resource "aws_iam_role_policy_attachment" "jenkins_admin" {
  role       = aws_iam_role.jenkins_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# "Conteneur" pour attacher rôle à EC2
# Crée rôle IAM pour Jenkins avec permissions complètes AWS.
# Crée Instance Profile pour attacher rôle à EC2 Jenkins.
# Jenkins peut maintenant gérer tout AWS (EKS, S3, EC2, etc.)."
resource "aws_iam_instance_profile" "jenkins_profile" {
  name = "jenkins-instance-profile"
  role = aws_iam_role.jenkins_role.name
}