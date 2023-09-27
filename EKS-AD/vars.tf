variable "AWS_REGION" {
  default = "us-east-2"
}

variable "default_VPC_id" {
  description = "CIDR for Test EKS VPC"
  default     = "vpc-07b2af77184cf668e"
}

variable "asg_sub_pub_a_cidr" {
  description = "CIDR for Public Subnet A"
  default     = "172.31.64.0/28"
}

variable "asg_sub_pub_b_cidr" {
  description = "CIDR for Public Subnet A"
  default     = "172.31.65.0/28"
}