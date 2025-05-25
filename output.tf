/*# output of ip of k3s master
output "master_private_ip" {
  depends_on = [aws_instance.master]
  value      = aws_instance.master.private_ip
}*/