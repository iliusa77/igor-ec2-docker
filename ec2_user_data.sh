#!/bin/bash

# Docker and compose installation
apt update
apt install -y net-tools curl docker.io haproxy git awscli
usermod -aG docker ubuntu
curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Clone private Gitlab repo
cd /home/ubuntu
git clone https://iliusa77:${gitlab_test_token}@gitlab.com/iliusa77/test-repo-for-igor.git

# Docker compose file creation
touch /home/ubuntu/docker-compose.yml
cat << EOF > /home/ubuntu/docker-compose.yml
version: "3.9"

services:
  user-mongo:
    image: mongo:4.4
    container_name: user-mongo
    ports:
      - "83:27017"
    networks:
      default:
        ipv4_address: 172.20.1.2

  requests-mongo:
    image: mongo:4.4
    container_name: requests-mongo
    ports:
      - "82:27017"
    networks:
      default:
        ipv4_address: 172.20.1.3

  connector:
    image: yenigul/dockernettools:latest
    networks:
      default:
        ipv4_address: 172.20.1.4


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

  frontend user_mongo_frontend
    mode tcp
    bind *:27183
    use_backend user_mongo

  frontend requests_mongo_frontend
    mode tcp
    bind *:27182
    use_backend requests_mongo

 backend user_mongo
      server user_mongo 172.20.1.2:27017 check

  backend requests_mongo
      server requests_mongo 172.20.1.3:27017 check
EOF'

# Start docker-compose
chown ubuntu:ubuntu /home/ubuntu/docker-compose.yml
docker-compose -f /home/ubuntu/docker-compose.yml up -d

# Start Haproxy
systemctl enable haproxy
systemctl restart haproxy
