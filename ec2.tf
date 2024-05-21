resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = var.public_key
}

resource "aws_instance" "server" {
  ami                     = var.ami #Ubuntu 20.04
  instance_type           = var.instance_type
  key_name                = "deployer-key"
  subnet_id               = module.vpc.public_subnets[0]
  vpc_security_group_ids = ["${module.vpc.default_security_group_id}"]
  associate_public_ip_address = true

  root_block_device {
    delete_on_termination = true
    encrypted             = false
    iops                  = var.root_block_iops
    throughput            = var.root_block_throughput
    volume_size           = var.root_block_volume_size
    volume_type           = var.root_block_volume_type
  }

  user_data = <<EOF
#!/bin/bash
apt update
apt install -y net-tools curl docker.io supervisor
usermod -aG docker ubuntu
curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

touch /home/ubuntu/docker-compose.yml
bash -c 'cat << EOF > /home/ubuntu/docker-compose.yml
version: "3.9"

services:
  web:
    image: nginx:latest
    ports:
     - 80

  php-fpm:
    image: php:8.2-fpm

  db:
    image: mysql:latest
    ports:
      - 3306
    environment:
      - MYSQL_ROOT_PASSWORD=strOnGpAsswOrD@
      - MYSQL_ALLOW_EMPTY_PASSWORD=strOnGpAsswOrD@
      - MYSQL_RANDOM_ROOT_PASSWORD=strOnGpAsswOrD@
EOF'

chown ubuntu:ubuntu /home/ubuntu/docker-compose.yml
docker-compose -f /home/ubuntu/docker-compose.yml up -d

EOF

  tags = {
    Name        = "server-docker-compose"
    Environment = "stage"
  }

  depends_on = [
    module.vpc
  ]
}