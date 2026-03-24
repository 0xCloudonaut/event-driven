# Creating eks cluster for observability stack using terraform eks module 
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.15.1"

  name            = local.cluster_name
  kubernetes_version = "1.33"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {}

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}

# Creating fargate profile for the observability stack
module "fargate_profile" {
  source = "terraform-aws-modules/eks/aws//modules/fargate-profile"

  name         = "observability-fargate-profile"
  cluster_name = module.eks.cluster_name

  subnet_ids = module.vpc.private_subnets
  selectors = [
    {namespace = "kube-system"}, 
    {namespace = "default"}
  ]

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}