output "master_ip_addr" {
  depends_on = [aws_instance.master]
  value      = aws_instance.master.private_ip
}
