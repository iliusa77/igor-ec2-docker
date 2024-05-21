### Generate SSH pair
```
ssh-keygen -t rsa -b 4096 -f ./ec2-docker-ssh-key
chmod 400 ec2-docker-ssh-key
```

Define SSH public key (ec2-docker-ssh-key.pub) in `vars.tf` public_key 

### Terraform init/plan/apply
```
terraform init

terraform plan
var.profile
  AWS credentials profile you want to use
  Enter a value: default

terraform apply -auto-approve
var.profile
  AWS credentials profile you want to use
  Enter a value: default
```

### Connect to to EC2 instance
```
ssh ubuntu@<instance_ip_addr> -i ec2-docker-ssh-key
```

### Check docker containers stack
```
cd /home/ubuntu
docker-compose ps
```

### Terraform cleanup
```
terraform destroy -auto-approve
```

