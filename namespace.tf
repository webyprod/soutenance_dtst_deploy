resource "kubernetes_namespace" "prod" {
  metadata {
    name = "prod"
  }
}

resource "kubernetes_namespace" "preprod" {
  metadata {
    name = "preprod"
  }
}
