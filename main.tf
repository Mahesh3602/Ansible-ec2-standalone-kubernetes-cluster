################################
# Provider
################################
provider "aws" {
  region = "us-east-1"
}

################################
# Variables
################################
variable "private_key_path" {
  description = "Path to SSH private key"
  type        = string
  default     = "~/.ssh/id_rsa"
}

################################
# Key Pair
################################
resource "aws_key_pair" "ec2_key" {
  key_name   = "my-terraform-key"
  public_key = file("${var.private_key_path}.pub")

  tags = {
    Project = "kubernetes-lab"
  }
}

################################
# Networking
################################
resource "aws_vpc" "k8s_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "k8s-vpc"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.k8s_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "k8s-public-subnet"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.k8s_vpc.id

  tags = {
    Name = "k8s-igw"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.k8s_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "k8s-public-rt"
  }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

################################
# Security Group
################################
resource "aws_security_group" "k8s_sg" {
  name   = "k8s-sg"
  vpc_id = aws_vpc.k8s_vpc.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Kubernetes API"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.k8s_vpc.cidr_block]
  }

  ingress {
    description = "Internal cluster traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_vpc.k8s_vpc.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "k8s-sg"
  }
}

################################
# AMI
################################
data "aws_ami" "ubuntu_24_04" {
  most_recent = true

  filter {
    name   = "name"
    values = ["*ubuntu-noble-24.04-amd64-server-*"]
  }

  owners = ["099720109477"]
}

################################
# EC2 Instances
################################

# Control Plane
resource "aws_instance" "control_plane" {
  ami           = data.aws_ami.ubuntu_24_04.id
  instance_type = "t3.small"

  key_name               = aws_key_pair.ec2_key.key_name
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.k8s_sg.id]

  tags = {
    Name = "control-plane-01"
    Role = "control-plane"
  }
}

# Worker Node 1
resource "aws_instance" "worker_01" {
  ami           = data.aws_ami.ubuntu_24_04.id
  instance_type = "t3.small"

  key_name               = aws_key_pair.ec2_key.key_name
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.k8s_sg.id]

  tags = {
    Name = "worker-01"
    Role = "worker"
  }
}

# Worker Node 2
resource "aws_instance" "worker_02" {
  ami           = data.aws_ami.ubuntu_24_04.id
  instance_type = "t3.small"

  key_name               = aws_key_pair.ec2_key.key_name
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.k8s_sg.id]

  tags = {
    Name = "worker-02"
    Role = "worker"
  }
}

################################
# Outputs (for Ansible)
################################
output "control_plane_ip" {
  value       = aws_instance.control_plane.public_ip
  description = "Control plane public IP"
}

output "worker_ips" {
  value = [
    aws_instance.worker_01.public_ip,
    aws_instance.worker_02.public_ip
  ]
  description = "Worker node public IPs"
}
