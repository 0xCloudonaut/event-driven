# Creating vpc named observability_vpc for eks cluster using terraform vpc module

module "observability_vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "observability_vpc"
  cidr = var.vpc_cidr

  azs             = var.azs
  private_subnets = var.private_subnet_cidr
  public_subnets  = var.public_subnet_cidr

  tags = {
    Name = "observability_vpc"
  }
}
