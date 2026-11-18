resource "aws_vpc" "main" {
  cidr_block            = "10.0.0.0/16"

  tags = {
    Name                = "main"
  }
}

resource "aws_subnet" "public" {
  vpc_id                = aws_vpc.main.id
  cidr_block            = "10.0.1.0/24"
  availability_zone     = "us-east-2b"

  tags = {
    Name                = "Main"
  }
}

resource "aws_subnet" "private" {
  vpc_id                = aws_vpc.main.id
  cidr_block            = "10.0.11.0/24"
  availability_zone     = "us-east-2a"

  tags = {
    Name                = "Main"
  }
}

resource "aws_subnet" "private1" {
  vpc_id                = aws_vpc.main.id
  cidr_block            = "10.0.12.0/24"
  availability_zone     = "us-east-2b"

  tags = {
    Name                = "Main"
  }
}

  resource "aws_subnet" "private2" {
  vpc_id                = aws_vpc.main.id
  cidr_block            = "10.0.13.0/24"
  availability_zone     = "us-east-2c"

  tags = {
    Name                = "Main"
  }  
}

resource "aws_internet_gateway" "main" {
  vpc_id                = aws_vpc.main.id

  tags = {
    Name                = "main"
  }
}

resource "aws_eip" "main" {
  domain                = "vpc"

   tags = {
    Name                = "main"
  }
}

resource "aws_nat_gateway" "main" {
  allocation_id         = aws_eip.main.id
  subnet_id             = aws_subnet.public.id

  tags = {
    Name                = "main"
  }

  depends_on = [aws_internet_gateway.main]
}

resource "aws_eks_cluster" "k8s" {
  name                  = "k8s-cluster"

  access_config {
    authentication_mode = "API"
  }

  role_arn              = aws_iam_role.cluster.arn
  version               = "1.35"

  vpc_config {
    subnet_ids = [
      aws_subnet.private.id,
      aws_subnet.private1.id,
      aws_subnet.private2.id,
    ]
  }

  # Ensure that IAM Role permissions are created before and deleted
  # after EKS Cluster handling. Otherwise, EKS will not be able to
  # properly delete EKS managed EC2 infrastructure such as Security Groups.
  depends_on = [
    aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy,
  ]
}

resource "aws_iam_role" "cluster" {
  name = "eks-cluster-example"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}
