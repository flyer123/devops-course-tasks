data "aws_availability_zones" "available-azs" {
  state = "available"
}

resource "aws_vpc" "vpc-tf" {
  cidr_block = var.cidr_block_vpc
  tags = {
    Name = "terraform-vpc"
  }
}

resource "aws_subnet" "public-subnets-tf" {
  count             = 2
  depends_on        = [aws_vpc.vpc-tf]
  vpc_id            = aws_vpc.vpc-tf.id
  cidr_block        = "10.20.${count.index}.0/24"
  availability_zone = tolist(data.aws_availability_zones.available-azs.names)[count.index]
  tags = {
    Name = "public-subnet-${count.index}"
  }
}

resource "aws_subnet" "private-subnets-tf" {
  count             = 2
  depends_on        = [aws_vpc.vpc-tf]
  vpc_id            = aws_vpc.vpc-tf.id
  cidr_block        = "10.20.${count.index + 2}.0/24"
  availability_zone = tolist(data.aws_availability_zones.available-azs.names)[count.index]
  tags = {
    Name = "private-subnet-${count.index}"
  }
}


# internet gateway
resource "aws_internet_gateway" "internet-gateway" {
  vpc_id = aws_vpc.vpc-tf.id
  tags = {
    Name = "terraform-igw"
  }
}

# route table for public subnets
resource "aws_route_table" "public-rtb" {
  vpc_id     = aws_vpc.vpc-tf.id
  depends_on = [aws_internet_gateway.internet-gateway]
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet-gateway.id
  }

  tags = {
    Name = "terraform_public_rtb"
    Tier = "public"
  }
}


# route table for private subnets
resource "aws_route_table" "private-rtb" {
  vpc_id = aws_vpc.vpc-tf.id

  route {
    cidr_block = "0.0.0.0/0"
    # nat_instance here
  }
  tags = {
    Name = "terraform-private-rtb"
    Tier = "private"
  }
}

# public subnet route table association
resource "aws_route_table_association" "public" {
  depends_on     = [aws_subnet.public-subnets-tf]
  route_table_id = aws_route_table.public-rtb.id
  count          = 2
  subnet_id      = aws_subnet.public-subnets-tf[count.index].id
}

# private subnet route table association
resource "aws_route_table_association" "private" {
  depends_on     = [aws_subnet.private-subnets-tf]
  route_table_id = aws_route_table.private-rtb.id
  count          = 2
  subnet_id      = aws_subnet.private-subnets-tf[count.index].id
}

# NAT-instance
