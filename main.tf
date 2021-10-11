# provider 
provider "aws" {
    region  = "ap-south-1"
}

# key variable
variable "key_name" {
  default = "ec2Key"
}

# base_path variable
variable "base_path" {
  default = "/home/Vikrant/terra-infra/"
}

# private key 
resource "tls_private_key" "private_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# aws keypair
resource "aws_key_pair" "key_pair" {
  depends_on = [tls_private_key.private_key]
  key_name   = var.key_name
  public_key = tls_private_key.private_key.public_key_openssh
}

# save privateKey
resource "local_file" "saveKey" {
  depends_on = [aws_key_pair.key_pair]
  content = tls_private_key.private_key.private_key_pem
  filename = "${var.base_path}${var.key_name}.pem"
}

# vpc
resource "aws_vpc" "vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "my-vpc"
  }

  enable_dns_hostnames = true
}

# public subnet
resource "aws_subnet" "public_subnet" {
  depends_on = [
    aws_vpc.vpc,
  ]

  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.0.0.0/24"

  availability_zone_id = "aps1-az1"

  tags = {
    Name = "public-subnet"
  }

  map_public_ip_on_launch = true
}

# private subnet
resource "aws_subnet" "private_subnet" {
  depends_on = [
    aws_vpc.vpc,
  ]

  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.0.1.0/24"

  availability_zone_id = "aps1-az3"

  tags = {
    Name = "private-subnet"
  }
}

# internet gateway
resource "aws_internet_gateway" "internet_gateway" {
  depends_on = [
    aws_vpc.vpc,
  ]

  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "internet-gateway"
  }
}

# route table with target as internet gateway
resource "aws_route_table" "IG_route_table" {
  depends_on = [
    aws_vpc.vpc,
    aws_internet_gateway.internet_gateway,
  ]

  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }

  tags = {
    Name = "IG-route-table"
  }
}

# associate route table to public subnet
resource "aws_route_table_association" "associate_routetable_to_public_subnet" {
  depends_on = [
    aws_subnet.public_subnet,
    aws_route_table.IG_route_table,
  ]
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.IG_route_table.id
}

# elastic ip
resource "aws_eip" "elastic_ip" {
  vpc      = true
}

# NAT gateway
resource "aws_nat_gateway" "nat_gateway" {
  depends_on = [
    aws_subnet.public_subnet,
    aws_eip.elastic_ip,
  ]
  allocation_id = aws_eip.elastic_ip.id
  subnet_id     = aws_subnet.public_subnet.id

  tags = {
    Name = "nat-gateway"
  }
}

# route table with target as NAT gateway
resource "aws_route_table" "NAT_route_table" {
  depends_on = [
    aws_vpc.vpc,
    aws_nat_gateway.nat_gateway,
  ]

  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_gateway.id
  }

  tags = {
    Name = "NAT-route-table"
  }
}

# associate route table to private subnet
resource "aws_route_table_association" "associate_routetable_to_private_subnet" {
  depends_on = [
    aws_subnet.private_subnet,
    aws_route_table.NAT_route_table,
  ]
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.NAT_route_table.id
}




# mysql security group
resource "aws_security_group" "sg_mysql" {
  depends_on = [
    aws_vpc.vpc,
  ]
  name        = "sg mysql"
  description = "Allow mysql inbound traffic"
  vpc_id      = aws_vpc.vpc.id


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# mysql ec2 instance
resource "aws_instance" "mysql_instance" {
  depends_on = [
    aws_security_group.sg_mysql,
    aws_nat_gateway.nat_gateway,
    aws_route_table_association.associate_routetable_to_private_subnet,
  ]
  ami = "ami-0732b62d310b80e97"
  instance_type = "t2.micro"
  key_name = var.key_name
  vpc_security_group_ids = [aws_security_group.sg_mysql.id]
  subnet_id = aws_subnet.private_subnet.id
  
  tags = {
      Name = "mysql-instance"
  }
}
