### Generate SSH pair
```
ssh-keygen -t rsa -b 4096 -f ./ec2-docker-ssh-key
chmod 400 ec2-docker-ssh-key
```

### Update Terraform variables
Define you own values in `vars.tf`
- put ec2-docker-ssh-key.pub in public_key
- project
- region

and so on ...

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

### Check docker images
```
docker images
REPOSITORY                                                            TAG        IMAGE ID       CREATED          SIZE
<aws_account_id>.dkr.ecr.eu-west-2.amazonaws.com/hello-world-python   latest     b773e1d75a97   20 minutes ago   67MB
python                                                                3-alpine   ee0f568dec6d   43 hours ago     51.7MB
```

### Docker push image to ECR repository (manual)
```
aws ecr get-login-password --region eu-west-2 | docker login --username AWS --password-stdin <aws_account_id>.dkr.ecr.eu-west-2.amazonaws.com
docker push <aws_account_id>.dkr.ecr.eu-west-2.amazonaws.com/hello-world-python
```

### Connect to Nginx and Mysql docker containers
```
curl http://<instance_ip_addr>:80
telnet <instance_ip_addr> 3306
```

### Terraform cleanup
```
terraform destroy -auto-approve
```

