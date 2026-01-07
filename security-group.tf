resource "aws_security_group" "main_sg" {
  name        = "main-sg"
  description = "SG for EC2, RDS, EKS"
  vpc_id      = aws_vpc.main.id

  dynamic "ingress" {
    for_each = [
      { from = 22, to = 22 },
      { from = 80, to = 80 },
      { from = 443, to = 443 },
      { from = 25, to = 25 },
      { from = 465, to = 465 },
      { from = 6443, to = 6443 },
      { from = 27017, to = 27017 },
      { from = 3306, to = 3306 },
      { from = 3000, to = 10000 }
    ]

    content {
      from_port   = ingress.value.from
      to_port     = ingress.value.to
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "main-sg"
  }
}

/* Ajout 
resource "aws_security_group_rule" "allow_eks_to_rds" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  security_group_id        = aws_security_group.main_sg.id
  source_security_group_id = aws_eks_cluster.cluster.vpc_config[0].cluster_security_group_id
}*/