///////////////////////// Role for EKS cluster /////////////////////////

# Creating a role for eks cluster
resource "aws_iam_role" "eks_cluster_role" {
    name = "eks-cluster-role"

    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Action = "sts:AssumeRole"
                Principal = {
                    Service = "eks.amazonaws.com"
                }
                Effect = "Allow"
                Sid    = ""
            }
        ]
    })

    tags = {
        Name = "eks-cluster-role"
    }
}

# Attaching the amazon eks cluster policy to the role
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
    role       = aws_iam_role.eks_cluster_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

///////////////////////// Role for EKS worker nodes /////////////////////////

# Creating a role for eks worker nodes
resource "aws_iam_role" "eks_worker_role" {
    name = "eks-worker-role"

    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Action = "sts:AssumeRole"
                Principal = {
                    Service = "ec2.amazonaws.com"
                }
                Effect = "Allow"
                Sid    = ""
            }
        ]
    })

    tags = {
        Name = "eks-worker-role"
    }
}

# Attaching the amazon eks worker node policy to the role
resource "aws_iam_role_policy_attachment" "eks_worker_policy" {
    role       = aws_iam_role.eks_worker_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

# Attaching the amazon eks cni policy to the role
resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
    role       = aws_iam_role.eks_worker_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}