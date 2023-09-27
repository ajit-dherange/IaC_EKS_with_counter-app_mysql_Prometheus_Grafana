###
# Provider
provider "aws" {
  profile = "default"
  region  = var.AWS_REGION
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.17.0"
    }
  }
}


# Create pub subnets
resource "aws_subnet" "asg-sub-pub-a" {
  vpc_id                  = var.default_VPC_id
  cidr_block              = var.asg_sub_pub_a_cidr
  map_public_ip_on_launch = "true"
  availability_zone       = "us-east-2a"

  tags = {
    Name = "asg-sub-pub-a"
  }
}

resource "aws_subnet" "asg-sub-pub-b" {
  vpc_id                  = var.default_VPC_id
  cidr_block              = var.asg_sub_pub_b_cidr
  map_public_ip_on_launch = "true"
  availability_zone       = "us-east-2b"

  tags = {
    Name = "asg-sub-pub-b"
  }
}


# create EKS IAM role
resource "aws_iam_role" "eks-iam-role" {
  name = "myekstest-eks-iam-role"

  path = "/"

  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
  {
   "Effect": "Allow",
   "Principal": {
    "Service": "eks.amazonaws.com"
   },
   "Action": "sts:AssumeRole"
  }
 ]
}
EOF

}

# attach policies to the role
resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks-iam-role.name
}
resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly-EKS" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks-iam-role.name
}


#create EKS cluster
resource "aws_eks_cluster" "myekstest-eks" {
  name     = "myekstest-cluster-01"
  role_arn = aws_iam_role.eks-iam-role.arn

  vpc_config {
    subnet_ids = [aws_subnet.asg-sub-pub-a.id, aws_subnet.asg-sub-pub-b.id]
  }

  depends_on = [
    aws_iam_role.eks-iam-role,
  ]
}


# create worker node role
resource "aws_iam_role" "myekstest-workernodes" {
  name = "eks-node-group-example"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

# attach policies to worker node role
resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.myekstest-workernodes.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.myekstest-workernodes.name
}

resource "aws_iam_role_policy_attachment" "EC2InstanceProfileForImageBuilderECRContainerBuilds" {
  policy_arn = "arn:aws:iam::aws:policy/EC2InstanceProfileForImageBuilderECRContainerBuilds"
  role       = aws_iam_role.myekstest-workernodes.name
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.myekstest-workernodes.name
}


# create worker nodes
resource "aws_eks_node_group" "worker-node-group" {
  cluster_name    = aws_eks_cluster.myekstest-eks.name
  node_group_name = "myekstest-workernodes"
  node_role_arn   = aws_iam_role.myekstest-workernodes.arn
  subnet_ids      = [aws_subnet.asg-sub-pub-a.id, aws_subnet.asg-sub-pub-b.id]
  instance_types  = ["t3.medium"]

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
    #aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
  ]
}

resource "aws_ecr_repository" "counter_app" {
  name                 = "counter-app"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

/*

# terraform apply -destroy
*/

