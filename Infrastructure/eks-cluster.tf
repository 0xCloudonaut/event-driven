# Creating eks cluster for observability stack using terraform eks module 
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.15.1"

  name            = local.cluster_name
  kubernetes_version = "1.33"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = concat(module.vpc.private_subnets, module.vpc.public_subnets)

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
  cluster_name = local.cluster_name

  subnet_ids = module.vpc.private_subnets
  selectors = [{
    namespace = "kube-system"
  }]

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}

# Creating IAM role for fargate profile
resource "aws_iam_role" "fargate_pod_execution_role" {
  name = "eks-fargate-pod-execution-role"

  assume_role_policy = jsonencode({
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "eks-fargate-pods.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

# Attaching the role to the fargate profile
resource "aws_iam_role_policy_attachment" "fargate_pod_execution_role_policy_attachment" {
  role       = aws_iam_role.fargate_pod_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSAppMeshEnvoyAccess"
}