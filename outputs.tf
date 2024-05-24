output "instance_ip_addr" {
  value = "ssh ubuntu@${aws_instance.server.public_ip} -i ec2-docker-ssh-key"
}

output "hello_world_python_ecr_repo" {
  value = module.ecr.repository_url
}