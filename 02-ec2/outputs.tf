output "instance_public_ip" {
  value = aws_eip.this.public_ip
}
output "instance_public_dns" {
  value = aws_eip.this.public_dns
}
output "ssh_command" {
  value = "ssh -i ${trimsuffix(var.ssh_public_key_path, ".pub")} ubuntu@${aws_eip.this.public_ip}"
}