# Creating a random string resource for cluster name suffix
resource "random_string" "cluster_name_suffix" {
  length  = 8
  special = false
}

# Creating a local value for cluster name
locals {
  cluster_name = "observability-${random_string.cluster_name_suffix.result}"
}

# Creating vpc named observability_vpc for eks cluster using terraform vpc module

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "6.6.0"

  name = "observability-vpc"
  cidr = "10.0.0.0/16"

  azs             = var.azs
  private_subnets = var.private_subnet_cidr
  public_subnets  = var.public_subnet_cidr

  enable_nat_gateway  = true
  single_nat_gateway  = true

  # Adding tag for vpc for kubernetes eks module
  tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
  }

  # Adding private subnet tags for eks aws module
  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb" = "1"
  }

  # Adding public subnet tags for eks aws module
  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb" = "1"
  }

}