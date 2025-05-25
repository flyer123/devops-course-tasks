/*# NAT-instance ami
data "aws_ami" "amzn_linux_2023_ami" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

# NAT instance
resource "aws_instance" "nat_aws_instance" {
  ami                         = data.aws_ami.amzn_linux_2023_ami.id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.public-subnets-tf[0].id
  vpc_security_group_ids      = [aws_security_group.nat_instance_sg.id]
  associate_public_ip_address = true
  source_dest_check           = false
  user_data                   = <<-EOF
    #!/bin/bash
    sudo yum install iptables-services -y
    sudo systemctl enable iptables
    sudo systemctl start iptables

    # Turning on IP Forwarding
    sudo touch /etc/sysctl.d/custom-ip-forwarding.conf
    sudo chmod 666 /etc/sysctl.d/custom-ip-forwarding.conf
    sudo echo "net.ipv4.ip_forward=1" >> /etc/sysctl.d/custom-ip-forwarding.conf
    sudo sysctl -p /etc/sysctl.d/custom-ip-forwarding.conf

    # Making a catchall rule for routing and masking the private IP
    sudo /sbin/iptables -t nat -A POSTROUTING -o ens5 -j MASQUERADE
    sudo /sbin/iptables -F FORWARD
    sudo service iptables save

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



# k3s master instance
resource "aws_instance" "master" {
  depends_on             = [aws_ssm_parameter.k3s_token, aws_instance.nat_aws_instance]
  ami                    = "ami-09a9858973b288bdd"
  instance_type          = "t3.medium"
  subnet_id              = aws_subnet.private-subnets-tf[0].id
  vpc_security_group_ids = [aws_security_group.test_instance_sg.id]
  key_name               = var.ec2_key_name

  user_data = file("./master.sh")

  iam_instance_profile = aws_iam_instance_profile.k3s_master.name

  tags = {
    Name = "K3s_Master_instance"
    Tier = "private"
  }

}

# node instance
resource "aws_instance" "node" {
  depends_on             = [aws_ssm_parameter.k3s_token, aws_instance.master]
  ami                    = "ami-09a9858973b288bdd"
  instance_type          = "t3.medium"
  subnet_id              = aws_subnet.private-subnets-tf[1].id
  vpc_security_group_ids = [aws_security_group.test_instance_sg.id]
  key_name               = var.ec2_key_name


  user_data = data.template_file.node.rendered


  iam_instance_profile = aws_iam_instance_profile.k3s_node.name

  tags = {
    Name = "K3s_Node_instance"
    Tier = "private"
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

# ssm_parameter
resource "aws_ssm_parameter" "k3s_token" {
  name  = "k3s_token"
  value = "empty"
  type  = "String"
  #overwrite   = true

  lifecycle {
    ignore_changes = [value]
  }
}


# output of ip of k3s master
output "master_private_ip" {
  depends_on = [aws_instance.master]
  value      = aws_instance.master.private_ip
}

# put parameters role for master
resource "aws_iam_role" "put_parameters" {
  depends_on         = [aws_ssm_parameter.k3s_token]
  name               = "put_parameters"
  description        = "Role to permit ec2 to put parameters from Parameter Store"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

# role policy for master
resource "aws_iam_role_policy" "put_parameters" {
  depends_on = [aws_ssm_parameter.k3s_token]
  name       = "put_parameters"
  role       = aws_iam_role.put_parameters.name
  policy     = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ssm:GetParameters",
                "ssm:PutParameters",
                "ssm:PutParameter"
            ],
            "Resource": [
                "${aws_ssm_parameter.k3s_token.arn}"
            ]
        }

    ]
}
EOF
}

# instance profile for master
resource "aws_iam_instance_profile" "k3s_master" {
  depends_on = [aws_ssm_parameter.k3s_token]
  name       = "k3s_master"
  role       = aws_iam_role.put_parameters.name
}


# node template definition
data "template_file" "node" {
  template   = file("./node.sh")
  depends_on = [aws_instance.master]
  vars = {
    master_private_ip = aws_instance.master.private_ip
    region            = "eu-north-1"
  }
}


# node role to get tocken form ssm
resource "aws_iam_role" "get_parameters" {
  depends_on         = [aws_ssm_parameter.k3s_token]
  name               = "get_parameters"
  description        = "Role to permit ec2 to get parameters from Parameter Store"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

# role policy for node
resource "aws_iam_role_policy" "get_parameters" {
  depends_on = [aws_ssm_parameter.k3s_token]
  name       = "get_parameters"
  role       = aws_iam_role.get_parameters.name
  policy     = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ssm:GetParameters"
            ],
            "Resource": [
                "${aws_ssm_parameter.k3s_token.arn}"
            ]
        }
    ]
}
EOF
}

# instance profile for node
resource "aws_iam_instance_profile" "k3s_node" {
  depends_on = [aws_ssm_parameter.k3s_token]
  name       = "get_parameters"
  role       = aws_iam_role.get_parameters.name
}*/