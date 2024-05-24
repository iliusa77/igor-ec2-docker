resource "aws_key_pair" "deployer" {
  key_name   = "${var.project}-ssh-key"
  public_key = var.public_key
}

resource "aws_iam_instance_profile" "profile" {
  name = "server-docker-compose-instance-profile"
  role = aws_iam_role.role.name
}

resource "aws_instance" "server" {
  ami                         = var.ami
  instance_type               = var.instance_type
  key_name                    = "${var.project}-ssh-key"
  subnet_id                   = module.vpc.public_subnets[0]
  vpc_security_group_ids      = ["${module.vpc.default_security_group_id}"]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.profile.name
  user_data                   = templatefile("./ec2_user_data.sh", {
    hello_world_python_ecr_repo = "${module.ecr.repository_url}"
    region                      = "${var.region}",
  })

  root_block_device {
    delete_on_termination = true
    encrypted             = false
    iops                  = var.root_block_iops
    throughput            = var.root_block_throughput
    volume_size           = var.root_block_volume_size
    volume_type           = var.root_block_volume_type
  }

  tags = {
    Name        = "${var.project}-server"
    Environment = "dev"
  }

  depends_on = [
    module.vpc
  ]
}
