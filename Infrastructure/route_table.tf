# creating route table for the vpc
resource "aws_route_table" "eks_route_table" {
    vpc_id = aws_vpc.eks_vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.eks_igw.id
    }

    tags = {
        Name = "eks-route-table"
    }
}

# associating route table with public subnet
resource "aws_route_table_association" "eks_public_subnet" {
    subnet_id      = aws_subnet.eks_public_subnet.id
    route_table_id = aws_route_table.eks_route_table.id
}

# Creating route table for private subnet
resource "aws_route_table" "eks_private_route_table" {
    vpc_id = aws_vpc.eks_vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.eks_nat_gateway.id
    }

    tags = {
        Name = "eks-private-route-table"
    }
}

# associating route table with private subnet
resource "aws_route_table_association" "eks_private_subnet" {
    subnet_id      = aws_subnet.eks_private_subnet.id
    route_table_id = aws_route_table.eks_private_route_table.id
}