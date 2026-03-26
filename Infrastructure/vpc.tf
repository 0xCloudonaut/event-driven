# Creating vpc named observability_vpc for eks cluster using terraform vpc module

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "6.6.0"

  name = "EDA-vpc"
  cidr = var.vpc_cidr

  azs             = var.azs
  private_subnets = var.private_subnet_cidr
  public_subnets  = var.public_subnet_cidr

  enable_nat_gateway  = true
  single_nat_gateway  = true
}