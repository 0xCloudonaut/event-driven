# creating public subnet for eks vpc for load balancer
resource "aws_subnet" "eks_public_subnet" {
    vpc_id            = aws_vpc.eks_vpc.id
    cidr_block        = var.public_subnet_cidr
    availability_zone = "us-east-1a"
    map_public_ip_on_launch = true

    tags = {
        Name = "eks-public-subnet"
    }
}

# creating private subnet for eks vpc for prometheus and grafana setup
resource "aws_subnet" "eks_private_subnet" {
    vpc_id            = aws_vpc.eks_vpc.id
    cidr_block        = var.private_subnet_cidr
    availability_zone = "us-east-1a"

    tags = {
        Name = "eks-private-subnet"
    }
}
