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
  depends_on                  = [aws_security_group.nat_instance_sg]
  ami                         = data.aws_ami.amzn_linux_2023_ami.id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.public-subnets-tf[0].id
  vpc_security_group_ids      = [aws_security_group.nat_instance_sg.id]
  associate_public_ip_address = true
  source_dest_check           = false
  user_data = <<-EOF
    #!/bin/bash
    echo "Enabling IP forwarding"
    sysctl -w net.ipv4.ip_forward=1
    echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf

    iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
    iptables-save > /etc/iptables/rules.v4

  EOF
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


# test instances
resource "aws_instance" "nat_testing_aws_instances" {
  count                  = 2
  depends_on             = [aws_security_group.test_instance_sg]
  ami                    = data.aws_ami.amzn_linux_2023_ami.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.private-subnets-tf[count.index].id
  vpc_security_group_ids = [aws_security_group.test_instance_sg.id]
  key_name               = var.ec2_key_name

  root_block_device {
    volume_size = "8"
    volume_type = "gp2"
    encrypted   = true
  }

  tags = {
    Name = "nat_testing_aws_instance-${count.index}"
  }
}

# bastion host
resource "aws_instance" "bastion_host_instance" {
  #depends_on                      = [aws_security_group.test_instance_sg]
  ami                         = data.aws_ami.amzn_linux_2023_ami.id
  associate_public_ip_address = true
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.public-subnets-tf[0].id
  vpc_security_group_ids      = [aws_security_group.bastion_host_instance_sg.id]
  key_name                    = var.ec2_key_name

  root_block_device {
    volume_size = "8"
    volume_type = "gp2"
    encrypted   = true
  }

  tags = {
    Name = "bastion_host_instance"
    Tier = "public"
  }
}