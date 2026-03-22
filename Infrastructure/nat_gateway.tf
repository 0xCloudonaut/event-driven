# creating NAT gateway for the private subnet
resource "aws_nat_gateway" "eks_nat_gateway" {
    allocation_id = aws_eip.eks_nat_eip.id
    subnet_id    = aws_subnet.eks_public_subnet.id

    tags = {
        Name = "eks-nat-gateway"
    }
}
