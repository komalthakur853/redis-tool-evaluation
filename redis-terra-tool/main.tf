module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "Redis-us-east-2-non-prod-vpc"
  cidr = var.vpc_cidr

  azs             = data.aws_availability_zones.available.names
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  enable_dns_hostnames = true
  enable_nat_gateway   = true
  single_nat_gateway   = true

  tags = {
    Name        = "Redis-us-east-2-non-prod-vpc"
    Terraform   = "true"
    Environment = "non-prod"
  }

  public_subnet_tags = {
    Name        = "Jenkins-us-east-2-public-subnet"
    Terraform   = "true"
    Environment = "non-prod"
  }

  private_subnet_tags = {
    Name        = "Jenkins-us-east-2-private-subnet"
    Terraform   = "true"
    Environment = "non-prod"
  }
}

# Now we will create  security group 

module "redis_us_east_2_non_prod_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "redis-us-east-2-non-prod-sg"
  description = "Security group for redis-us-east-2-non-prod with specific ports open"
  vpc_id      = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "SSH"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 8080
      to_port     = 8080
      protocol    = "tcp"
      description = "Application port"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 6370
      to_port     = 6370
      protocol    = "tcp"
      description = "Redis port"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 8001
      to_port     = 8001
      protocol    = "tcp"
      description = "Application port"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 9090
      to_port     = 9090
      protocol    = "tcp"
      description = "Application port"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 3000
      to_port     = 3000
      protocol    = "tcp"
      description = "Application port"
      cidr_blocks = "0.0.0.0/0"
    },
  ]

  egress_with_cidr_blocks = [
    {
      from_port   = 3000
      to_port     = 3000
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  tags = {
    Name        = "redis-us-east-2-non-prod-sg"
    Environment = "non-prod"
    Terraform   = "true"
  }
}

module "ec2_instance" {
  source = "terraform-aws-modules/ec2-instance/aws"

  for_each = {
    "public" = {
      instance_type = "t2.micro"
      subnet_id     = module.vpc.public_subnets[0] # Use the first public subnet
      public_ip     = true
    }
    "private" = {
      instance_type = "t2.micro"
      subnet_id     = module.vpc.private_subnets[0] # Use the first private subnet
      public_ip     = false
    }
  }

  name                        = "instance-${each.key}"
  instance_type               = each.value.instance_type
  key_name                    = "aws"
  monitoring                  = true
  vpc_security_group_ids      = [module.redis_us_east_2_non_prod_sg.security_group_id]
  subnet_id                   = each.value.subnet_id
  associate_public_ip_address = each.value.public_ip
  ami                         = data.aws_ami.ubuntu.id
  tags = {
    Terraform   = "true"
    Environment = "non-prod"
  }
}
