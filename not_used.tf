/*# test instances
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


# bastion instance egress port 22
resource "aws_security_group_rule" "bastion_host_instance_ssh_eggress" {
  type              = "egress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.bastion_host_instance_sg.id
}



*/