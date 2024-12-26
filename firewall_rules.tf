# NAT security group
resource "aws_security_group" "nat_instance_sg" {
  depends_on  = [aws_vpc.vpc-tf]
  name        = "nat_instance_security_group"
  description = "Security group for NAT instance"
  vpc_id      = aws_vpc.vpc-tf.id

}

# security group for test instance
resource "aws_security_group" "test_instance_sg" {
  depends_on  = [aws_vpc.vpc-tf]
  name        = "test_instance_sg"
  description = "Security group NAT test instance"
  vpc_id      = aws_vpc.vpc-tf.id
}

# security group for bastion host instance
resource "aws_security_group" "bastion_host_instance_sg" {
  depends_on  = [aws_vpc.vpc-tf]
  name        = "bastion_host_instance_sg"
  description = "Security group bastion host instance"
  vpc_id      = aws_vpc.vpc-tf.id
}

# output connections to nat instance
resource "aws_security_group_rule" "nat_instance_output_sg_rule" {
  type              = "egress"
  from_port         = 1024
  to_port           = 65535
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.nat_instance_sg.id
}

# input connections to nat instance
resource "aws_security_group_rule" "nat_instance_inbound_sg_rule" {
  type              = "ingress"
  from_port         = 1024
  to_port           = 65535
  protocol          = "-1"
  cidr_blocks       = [var.cidr_block_vpc]
  security_group_id = aws_security_group.nat_instance_sg.id
}

# test instance input rules
resource "aws_security_group_rule" "nat_testing_instance_ingress" {
  type              = "ingress"
  from_port         = 1024
  to_port           = 65535
  protocol          = "-1"
  cidr_blocks       = var.public_cidr_blocks
  security_group_id = aws_security_group.test_instance_sg.id
}

# test instance output rules
resource "aws_security_group_rule" "nat_testing_instance_egress" {
  type              = "egress"
  from_port         = 1024
  to_port           = 65535
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.test_instance_sg.id
}

# nat instance ingress port 22 from bastion host

# nat instance egress port 22 from bastion host

# test instance ingress port 22 from bastion host

# test instance egress port 22 from bastion host

# bastion instance ingress port 22 from internet
resource "aws_security_group_rule" "bastion_host_instancessh__ingress" {
  type              = "ingress"
  from_port         = 1024
  to_port           = 1024
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.bastion_host_instance_sg.id
}