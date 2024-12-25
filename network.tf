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
    cidr_block           = "0.0.0.0/0"
    network_interface_id = aws_network_interface.network_interface.id
  }
  tags = {
    Name = "terraform-private-rtb"
    Tier = "private"
  }
}

# public subnet route table association
resource "aws_route_table_association" "public" {
  depends_on     = [aws_subnet.public-subnets-tf, aws_route_table.public-rtb]
  route_table_id = aws_route_table.public-rtb.id
  count          = 2
  subnet_id      = aws_subnet.public-subnets-tf[count.index].id
}

# private subnet route table association
resource "aws_route_table_association" "private" {
  depends_on     = [aws_subnet.private-subnets-tf, aws_route_table.private-rtb]
  route_table_id = aws_route_table.private-rtb.id
  count          = 2
  subnet_id      = aws_subnet.private-subnets-tf[count.index].id
}



# NAT-instance ami
data "aws_ami" "amzn_linux_2023_ami" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

resource "aws_instance" "nat_aws_instance" {
  count                       = 1
  depends_on                  = [aws_security_group.nat_security_group, aws_network_interface.nat_network_interface]
  ami                         = data.aws_ami.amzn_linux_2023_ami.id
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public-subnets-tf[0]
  vpc_security_group_ids      = [aws_security_group.nat_security_group.id]
  associate_public_ip_address = true
  source_dest_check           = false
  network_interface {
    network_interface_id = aws_network_interface.nat_network_interface.id
    device_index         = 0
  }
  user_data                   = <<-EOL
                                        #! /bin/bash
                                        sudo yum install iptables-services -y
                                        sudo systemctl enable iptables
                                        sudo systemctl start iptables
                                        sudo sysctl -w net.ipv4.ip_forward=1
                                        sudo /sbin/iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
                                        sudo /sbin/iptables -F FORWARD
    EOL
  user_data_replace_on_change = true
  key_name                    = var.ec2_key_name

  root_block_device {
    volume_size = "8"
    volume_type = "gp2"
    encrypted   = true
  }
  tags = {
    Name = "NAT_instance"
    Tier = "public"
  }
}

# NAT security group
resource "aws_security_group" "nat_security_group" {
  depends_on  = [aws_vpc.vpc-tf]
  name        = "nat_instance_security_group"
  description = "Security group for NAT instance"
  vpc_id      = aws_vpc.vpc-tf.id

  ingress = [
    {
      description      = "Ingress CIDR"
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = [cidr_block_vpc]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = true
    }
  ]

  egress = [
    {
      description     = "Default egress"
      from_port       = 0
      to_port         = 0
      protocol        = "-1"
      cidr_blocks     = ["0.0.0.0/0"]
      prefix_list_ids = []
      security_groups = []
      self            = true
    }
  ]
}


# add separate network interface to EC2 NAT instance
resource "aws_network_interface" "nat_network_interface" {
  depends_on        = [aws_security_group.nat_security_group]
  subnet_id         = aws_subnet.public-subnets-tf[0]
  source_dest_check = false
  security_groups   = [aws_security_group.security_group.id]

  tags = {
    Name = "nat_instance_network_interface"
  }
}

