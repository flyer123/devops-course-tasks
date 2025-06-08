/*# output of ip addre of k3s master
output "master_private_ip" {
  depends_on = [aws_instance.master]
  value      = aws_instance.master.private_ip
}

#output of public ip addr of bastion host 
output "bastion_public_ip" {
  depends_on = [aws_instance.bastion_host_instance]
  value      = aws_instance.bastion_host_instance.public_ip
}*/