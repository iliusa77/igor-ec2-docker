#!/bin/bash

# Docker and compose installation
apt update
apt install -y net-tools curl docker.io haproxy git awscli
usermod -aG docker ubuntu
curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Get code & Docker  build/login/push
git clone https://github.com/datawire/hello-world-python.git
cd hello-world-python
docker build -t ${hello_world_python_ecr_repo}:latest .
aws ecr get-login-password --region ${region} | docker login --username AWS --password-stdin ${hello_world_python_ecr_repo}
docker push ${hello_world_python_ecr_repo}

docker build -t ${frontend1_ecr_repo}:latest .
aws ecr get-login-password --region ${region} | docker login --username AWS --password-stdin ${frontend1_ecr_repo}
docker push ${frontend1_ecr_repo}

docker build -t ${backend1_ecr_repo}:latest .
aws ecr get-login-password --region ${region} | docker login --username AWS --password-stdin ${backend1_ecr_repo}
docker push ${backend1_ecr_repo}

# Docker compose file creation
touch /home/ubuntu/docker-compose.yml
cat << EOF > /home/ubuntu/docker-compose.yml
version: "3.9"

services:
  hello-world-python:
    image: ${hello_world_python_ecr_repo}:latest
    ports:
     - 8080
    networks:
      default:
        ipv4_address: 172.20.1.1

  frontend1:
    image: ${frontend1_ecr_repo}:latest
    networks:
      default:
        ipv4_address: 172.20.1.2

  backend1:
    image: ${backend1_ecr_repo}:latest
    networks:
      default:
        ipv4_address: 172.20.1.4

  db:
    image: mysql:latest
    ports:
      - 3306
    environment:
      - MYSQL_ROOT_PASSWORD=strOnGpAsswOrD@
      - MYSQL_ALLOW_EMPTY_PASSWORD=strOnGpAsswOrD@
      - MYSQL_RANDOM_ROOT_PASSWORD=strOnGpAsswOrD@
    networks:
      default:
        ipv4_address: 172.20.1.3

networks:
  default:
    external:
      name: develop     
EOF

# External docker network creation
docker network create develop --subnet=172.20.0.0/16

# Haproxy configuration
bash -c 'cat << EOF > /etc/haproxy/haproxy.cfg
global
        log /dev/log    local0
        log /dev/log    local1 notice
        chroot /var/lib/haproxy
        stats socket /run/haproxy/admin.sock mode 660 level admin expose-fd listeners
        stats timeout 30s
        user haproxy
        group haproxy
        daemon

        # Default SSL material locations
        ca-base /etc/ssl/certs
        crt-base /etc/ssl/private

        # See: https://ssl-config.mozilla.org/#server=haproxy&server-version=2.0.3&config=intermediate
        ssl-default-bind-ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384
        ssl-default-bind-ciphersuites TLS_AES_128_GCM_SHA256:TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256
        ssl-default-bind-options ssl-min-ver TLSv1.2 no-tls-tickets

defaults
        log     global
        mode    http
        option  httplog
        option  dontlognull
        timeout connect 5000
        timeout client  50000
        timeout server  50000
        errorfile 400 /etc/haproxy/errors/400.http
        errorfile 403 /etc/haproxy/errors/403.http
        errorfile 408 /etc/haproxy/errors/408.http
        errorfile 500 /etc/haproxy/errors/500.http
        errorfile 502 /etc/haproxy/errors/502.http
        errorfile 503 /etc/haproxy/errors/503.http
        errorfile 504 /etc/haproxy/errors/504.http

  frontend hello-world-python_frontend
    bind *:8080
    use_backend hello-world-python

  frontend mysql_frontend
    mode tcp
    bind *:3306
    use_backend mysql

  backend hello-world-python
    server hello-world-python 172.20.1.1:8080 check

  backend mysql
    server mysql 172.20.1.3:3306 check
EOF'

# Start docker-compose
chown ubuntu:ubuntu /home/ubuntu/docker-compose.yml
docker-compose -f /home/ubuntu/docker-compose.yml up -d

# Start Haproxy
systemctl enable haproxy
systemctl restart haproxy
