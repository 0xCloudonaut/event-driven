# creating internet gateway for the vpc
resource "aws_internet_gateway" "eks_igw" {
    vpc_id = aws_vpc.eks_vpc.id

    tags = {
        Name = "eks-igw"
    }
}