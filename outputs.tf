output "instance_ip_addr" {
  value = "ssh ubuntu@${aws_instance.server.public_ip} -i ec2-docker-ssh-key"
}

# output "ecr_repos_list" {
#   value = [module.ecr[0].repository_url,module.ecr[1].repository_url,module.ecr[2].repository_url]
# }