output "instance_ip_addr" {
  value = "ssh ubuntu@${aws_instance.server.public_ip} -i ec2-docker-ssh-key"
}