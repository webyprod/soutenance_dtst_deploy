resource "kubernetes_secret" "backend_db" {
  depends_on = [
    kubernetes_namespace.prod,
    aws_eks_node_group.nodegroup
  ]

  metadata {
    name      = "backend-db-secret"
    namespace = "prod"
  }

  data = {
    SPRING_DATASOURCE_URL      = "jdbc:mysql://${aws_db_instance.mysql.address}:${aws_db_instance.mysql.port}/userdb?serverTimezone=Europe/Paris"
    SPRING_DATASOURCE_USERNAME = aws_db_instance.mysql.username
    SPRING_DATASOURCE_PASSWORD = aws_db_instance.mysql.password
  }
}