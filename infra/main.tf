# Set aws provider
# provider "aws" {
#   region = lookup(var.awsprops, "region")
# }

# Manage state file in the backend S3
terraform {
  backend "s3" {
    bucket         = "demo-infra-state"
    key            = "demo/terraform.tfstate"
    region         = "us-east-1"
  }
}

# VPC
resource "aws_vpc" "demo-vpc" {
  cidr_block = var.cidr
  enable_dns_hostnames = true

    tags = {
    Name = "Demo VPC"
  }
}

#  An Internet Gateway for the VPC.
resource "aws_internet_gateway" "igw" {
  vpc_id = "${aws_vpc.demo-vpc.id}"
}

# Public subnets
resource "aws_subnet" "pub-sub" {
  count=2
  vpc_id = "${aws_vpc.demo-vpc.id}"

  availability_zone = "${var.azs[count.index]}"
  cidr_block        = cidrsubnet(aws_vpc.demo-vpc.cidr_block, 8, count.index)
  map_public_ip_on_launch = true
  tags = {
      Name= "pub-sub-${count.index}"
  }
}

# Private subnets for RDS
resource "aws_subnet" "db-sub" {
  count=2
  vpc_id = "${aws_vpc.demo-vpc.id}"

  availability_zone = "${var.azs[count.index]}"
  cidr_block        = cidrsubnet(aws_vpc.demo-vpc.cidr_block, 8, count.index+2)
  map_public_ip_on_launch = false
  tags = {
      Name= "db-sub-${count.index}"
  }
}

# Create EIP
resource "aws_eip" "eip" {
  vpc = true
}

# NAT gateway
resource "aws_nat_gateway" "nat_gateway" {
  #vpc_id = "${aws_vpc.demo-vpc.id}"
  allocation_id = aws_eip.eip.id
  subnet_id = "${element(aws_subnet.pub-sub.*.id, 1)}"
  tags = {
    "Name" = "NAT Gateway"
  }
}

# Route table for private subnet
resource "aws_route_table" "rt-private" {
  vpc_id = aws_vpc.demo-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_gateway.id
  }

   tags = {
    Name = "rt-private"
  }
}

# route table for public subnet
resource "aws_route_table" "rt-pub" {
  vpc_id = "${aws_vpc.demo-vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.igw.id}"
  }

  tags = {
    Name = "rt-public"
  }
}

# Route table associations
resource "aws_route_table_association" "public-rt-assoc" {
  count       = 2
  subnet_id      = "${element(aws_subnet.pub-sub.*.id, count.index)}"
  route_table_id = "${aws_route_table.rt-pub.id}"
}

# Route table association to private subnet
resource "aws_route_table_association" "private-rt-assoc" {
  count = 2
  subnet_id = aws_subnet.db-sub[count.index].id
  route_table_id = aws_route_table.rt-private.id
}

# Security groups
# Alb SG
resource "aws_security_group" "alb-sg" {
  name        = "alb_security_group"
  description = "load balancer security group"
  vpc_id      = "${aws_vpc.demo-vpc.id}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "alb-security-group"
  }
}

# Public SG for webservers
resource "aws_security_group" "pub-demo-sg1" {
  name = var.pub-sg
  description = var.pub-sg
  vpc_id = "${aws_vpc.demo-vpc.id}"

  # To Allow SSH 
  ingress {
    from_port = 22
    protocol = "tcp"
    to_port = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  # To Allow Port 80 
  ingress {
    from_port = 80
    protocol = "tcp"
    to_port = 80
    security_groups = [
        "${aws_security_group.alb-sg.id}"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

# RDS SG
resource "aws_security_group" "db-demo-sg1" {
  name = var.db-sg
  description = var.db-sg
  vpc_id = "${aws_vpc.demo-vpc.id}"

  # To Allow Postgres connection from  Web layer
  ingress {
    from_port = 5432
    protocol = "tcp"
    to_port = 5432
    security_groups = [
        "${aws_security_group.pub-demo-sg1.id}"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Web servers
resource "aws_instance" "pub-ins-proj-demo" {
  count=2
  ami = lookup(var.awsprops, "ami")
  instance_type = lookup(var.awsprops, "itype")
  subnet_id = "${element(aws_subnet.pub-sub.*.id, count.index)}"
  associate_public_ip_address = lookup(var.awsprops, "publicip")
  key_name = lookup(var.awsprops, "keyname")

  vpc_security_group_ids = [
    aws_security_group.pub-demo-sg1.id
  ]
  root_block_device {
    delete_on_termination = true
    iops = 150
    volume_size = 50
    volume_type = "gp3"
  }
  tags = {
    Name ="WEBSERVER${count.index}"
    Environment = "DEV"
    Managed = "Terraform"
  }

  depends_on = [ aws_security_group.pub-demo-sg1 ]
}

# DB subnet group with private subnets for RDS
resource aws_db_subnet_group "db-sub-grp"{
  name       = "db-sub-grp"
  subnet_ids = [for subnet in aws_subnet.db-sub : subnet.id]

  tags = {
    Name = "Education"
  }
}

resource aws_db_parameter_group "db-params" {
  family = "postgres13"
  parameter {
    apply_method = "immediate"
    name         = "autovacuum_naptime"
    value        = "30"
  }
  parameter {
    apply_method = "pending-reboot"
    name         = "autovacuum_max_workers"
    value        = "15"
  }
}

# RDS instance for postgres
resource "aws_db_instance" "db-ins-proj-demo" {
  identifier             = "db-instance"
  instance_class         = "db.t3.micro"
  allocated_storage      = 5
  engine                 = "postgres"
  #engine_version         = "13.1"
  username               = "manohar"
  password               = "password"
  db_subnet_group_name   = aws_db_subnet_group.db-sub-grp.name
  vpc_security_group_ids = [aws_security_group.db-demo-sg1.id]
  parameter_group_name   = aws_db_parameter_group.db-params.name
  publicly_accessible    = true
  skip_final_snapshot    = true
}

# Setup lb for web servers
resource "aws_alb" "demo-alb" {
  name               = "demo-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb-sg.id]
  subnets            = [for subnet in aws_subnet.pub-sub : subnet.id]

  enable_deletion_protection = false

  tags = {
    Name = "demo-alb"
    Environment = "Dev"
  }
}

# Target group
resource "aws_alb_target_group" "demo-tg" {
  name     = "demo-alb-target"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "${aws_vpc.demo-vpc.id}"
  stickiness {
    type = "lb_cookie"
  }
  # Alter the destination of the health check
  health_check {
    path = "/"
    port = 80
  }
}

// Register web servers to target group
resource "aws_lb_target_group_attachment" "tg_attachment_test1" {
    count = 2
    target_group_arn = aws_alb_target_group.demo-tg.arn
    target_id        = aws_instance.pub-ins-proj-demo[count.index].id
    port             = 80
}

# Listener to bind lb and target group
resource "aws_alb_listener" "listener_http" {
  load_balancer_arn = "${aws_alb.demo-alb.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_alb_target_group.demo-tg.arn}"
    type             = "forward"
  }
}

output "ec2instance" {
  value = aws_instance.pub-ins-proj-demo.*.public_ip
}