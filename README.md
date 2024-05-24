This demo repository provides deploy the following AWS resources with Terraform:
- VPC (include Subnets, Route Tables, NAT & Intrenet Gateways, Security Group)
- EC2 instance
- ECR repository 
- IAM role and policy for access from EC2 instance to ECR repository

After AWS infrastructure deploy, in EC2 instance will be deployed:
- Docker & Docker compose
- Demo docker-compose stack
- Haproxy as reverse proxy for docker containers 

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
php                                                                   8.2-fpm    2cc7a580ec9a   9 days ago       494MB
mysql                                                                 latest     e9387c13ed83   3 weeks ago      578MB
```

### Docker push image to ECR repository (manually, optional)
```
aws ecr get-login-password --region eu-west-2 | docker login --username AWS --password-stdin <aws_account_id>.dkr.ecr.eu-west-2.amazonaws.com
docker push <aws_account_id>.dkr.ecr.eu-west-2.amazonaws.com/hello-world-python
```

### Connect to Python and Mysql docker containers
```
curl http://<instance_ip_addr>:8080
telnet <instance_ip_addr> 3306
```

### Terraform cleanup
```
terraform destroy -auto-approve
```

