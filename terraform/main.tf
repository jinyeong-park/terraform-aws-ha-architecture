terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.76.0"
    }
  }
}

########################################
# Local Variables
########################################
locals {
  name        = "cluster"
  region      = "us-east-1"

  vpc_cidr    = "172.31.0.0/24"
  azs         = ["us-east-1a", "us-east-1b"]

  # 3 tier architecture with /27 subnets => NAT Gateway Trouble shooting
  public_subnet_1 = "172.31.0.0/27"      # Public subnet for AZ1
  public_subnet_2 = "172.31.0.32/27"     # Public subnet for AZ2
  private_subnet_web_1 = "172.31.0.64/27"  # Web server subnet in AZ1
  private_subnet_web_2 = "172.31.0.96/27"  # Web server subnet in AZ2
  private_subnet_db_1 = "172.31.0.128/27"  # DB subnet in AZ1
  private_subnet_db_2 = "172.31.0.160/27"  # DB subnet in AZ2

  # subnet줄이고, Bastion subnet에 조금 더 작은량 할당
  public_subnet_1 = "172.31.0.0/26"  # Bastion subnet for AZ1
  public_subnet_2 = "172.31.0.64/26" # Public subnet for AZ2
  private_subnet_1 = "172.31.0.128/26" # Web and db subnet in AZ1
  private_subnet_2 = "172.31.0.192/26" # Web and db subnet in AZ2

}

provider "aws" {
  region = local.region
}

########################################
# VPC Module
########################################
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name                = "my-vpc"
  cidr                = local.vpc_cidr
  azs                 = local.azs
  public_subnets      = [local.public_subnet_1, local.public_subnet_2]  # Two public subnets
  private_subnets     = [
    local.private_subnet_web_1, local.private_subnet_web_2,  # Web server subnets
    local.private_subnet_db_1, local.private_subnet_db_2     # DB subnets
  ]
  enable_nat_gateway   = false  # NAT Gateway disabled
  enable_dns_hostnames = true
  enable_dns_support   = true
}


########################################
# Application Load Balancer (ALB)
########################################
resource "aws_lb" "main" {
  name               = "my-alb"
  internal           = false  # Public ALB
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web_sg.id]

  # Specify two public subnets in different AZs for the ALB
  subnets            = [
    module.vpc.public_subnets[0],  # Public subnet in AZ1
    module.vpc.public_subnets[1]   # Public subnet in AZ2
  ]

  enable_deletion_protection    = false
  enable_cross_zone_load_balancing = true

  tags = {
    Name = "my-alb"
  }
}

resource "aws_lb_target_group" "web_target_group" {
  name     = "web-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id
}

resource "aws_lb_listener" "web_listener" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "fixed-response"
    fixed_response {
      status_code = 200
      content_type = "text/plain"
      message_body = "OK"
    }
  }
}



########################################
# Auto Scaling Group
########################################
resource "aws_autoscaling_group" "web" {
  desired_capacity    = 2
  max_size            = 5
  min_size            = 2
  vpc_zone_identifier = [
    module.vpc.private_subnets[0],  # Web server subnet in AZ1
    module.vpc.private_subnets[1]   # Web server subnet in AZ2
  ]
  
  launch_template {
    id      = aws_launch_template.web-server.id
    version = "$Latest"
  }

  health_check_type         = "EC2"
  health_check_grace_period = 300

  # Attach the target group to the Auto Scaling Group
  target_group_arns = [aws_lb_target_group.web_target_group.arn]
}

########################################
# Security Groups
########################################
resource "aws_security_group" "bastion_sg" {
  name        = "bastion-sg"
  description = "Allow SSH access"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Consider restricting to your IP
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "web_sg" {
  name        = "web-server-sg"
  description = "Allow HTTP and SSH traffic from Bastion Host"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]  # Allow SSH from Bastion Host SG
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "rds_sg" {
  name        = "rds-sg"
  description = "Allow MySQL traffic"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

########################################
# EC2 Instances for Bastion Host
########################################
resource "aws_key_pair" "bastion_key" {
  key_name   = "bastion-keypair"
  public_key = file("~/.ssh/id_rsa.pub") # Path to your existing public key or generate one
}

resource "aws_instance" "bastion" {
  ami           = "ami-012967cc5a8c9f891"
  instance_type = "t2.micro"

  key_name                    = aws_key_pair.bastion_key.key_name
  subnet_id                   = module.vpc.public_subnets[0]  # Bastion in public subnet AZ1
  vpc_security_group_ids      = [aws_security_group.bastion_sg.id]
  associate_public_ip_address = true

  tags = {
    Name = "BastionHost"
  }
}

resource "aws_launch_template" "web-server" {
  name          = "web-launch-template"
  image_id      = "ami-012967cc5a8c9f891"
  instance_type = "t2.micro"

  network_interfaces {
    security_groups = [aws_security_group.web_sg.id]
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "web-server"
    }
  }
}

########################################
# RDS
########################################
resource "aws_db_subnet_group" "my_db_subnet_group" {
  name        = "my-db-subnet-group"
  description = "My DB Subnet Group for private subnets"
  subnet_ids  = [
    module.vpc.private_subnets[2],  # DB subnet in AZ1
    module.vpc.private_subnets[3]   # DB subnet in AZ2
  ]

  tags = {
    Name = "my-db-subnet-group"
  }
}


resource "aws_db_instance" "myrds" {
  engine               = "mysql"
  engine_version       = "8.0.39"
  allocated_storage    = 20
  storage_type         = "gp3"
  identifier           = "todolist-db"
  db_name             = "todolist"
  instance_class      = "db.t3.micro"
  username            = "admin"
  password            = "newpassword123"  # Changed to meet minimum requirements
  publicly_accessible = false
  multi_az            = true
  
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.my_db_subnet_group.name

  tags = {
    Name = "my-rds"
  }
  # Ensure this is set for a final snapshot when deleting the instance
  skip_final_snapshot   = false
  final_snapshot_identifier = "todolist-db-final-snapshot"
}

## DB - us-east-1b만 생성됨
