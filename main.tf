provider "aws" {
  region = "us-east-1"  # Укажите ваш регион
}

# Создание VPC
resource "aws_vpc" "terr-jenk" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "terr-jenk-vpc"
  }
}

# Создание Subnet
resource "aws_subnet" "terr-jenk" {
  vpc_id            = aws_vpc.terr-jenk.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  
  map_public_ip_on_launch = true		#Try to map public IP

  tags = {
    Name = "terr-jenk-subnet"
  }
}

# Создание Internet Gateway
resource "aws_internet_gateway" "terr-jenk" {
  vpc_id = aws_vpc.terr-jenk.id

  tags = {
    Name = "terr-jenk-igw"
  }
}

# Создание Route Table
resource "aws_route_table" "terr-jenk" {
  vpc_id = aws_vpc.terr-jenk.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.terr-jenk.id
  }

  tags = {
    Name = "terr-jenk-route-table"
  }
}

# Ассоциация Route Table с Subnet
resource "aws_route_table_association" "terr-jenk" {
  subnet_id      = aws_subnet.terr-jenk.id
  route_table_id = aws_route_table.terr-jenk.id
}

# Security Group for Jenkins
resource "aws_security_group" "jenkins_sg" {
  vpc_id = aws_vpc.terr-jenk.id

  # Разрешение доступа по HTTP (80) и SSH (22)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Для безопасности измените этот параметр для Production
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Разрешает доступ по SSH отовсюду
  }
  
    ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Remote access to Jenkins by Public IP
  }

  # Разрешение всех исходящих соединений
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "jenkins-sg"
  }
}

# Create pub key 
resource "tls_private_key" "terr-jenk" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
# Add key pair
resource "aws_key_pair" "deployer" {
  key_name   = "my-key"
  public_key = tls_private_key.terr-jenk.public_key_openssh
}



# # EC2 for Jenkins
# resource "aws_instance" "jenkins-machine" {
#   ami           = "ami-03972092c42e8c0ca"  # Amazon Linux 2 AMI (в регионе us-east-1)
#   instance_type = "t2.micro"               # Free Tier
#   subnet_id     = aws_subnet.terr-jenk.id
#   vpc_security_group_ids = [aws_security_group.jenkins_sg.id]  # Замена security_groups на vpc_security_group_ids
# 
#   key_name = aws_key_pair.deployer.key_name  # SSH Key
#   
#   tags = {
#     Name = "Jenkins-Server"
#   }
# 
#   user_data = <<-EOF
#               #!/bin/bash
# 				#Install jenkins
# 				sudo yum update –y
# 				sudo wget -O /etc/yum.repos.d/jenkins.repo \
# 					https://pkg.jenkins.io/redhat-stable/jenkins.repo
# 				#	Import a key file from Jenkins-CI to enable installation from the package:
# 				sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key	
# 				sudo yum upgrade
# 
# 				#Install Java
# 				sudo yum install java-17-amazon-corretto -y
# 				# Install Jenkins:
# 				sudo yum install jenkins -y
# 				# Enable the Jenkins service to start at boot:
# 				sudo systemctl enable jenkins
# 				# Start Jenkins as a service:
# 				sudo systemctl start jenkins
#               EOF
# }

module "jenkins_ec2" {
  source = "./jenkins"


  vpc_id                  = aws_vpc.terr-jenk.id
  subnet_id               = aws_subnet.terr-jenk.id
  vpc_security_group_ids  = [aws_security_group.jenkins_sg.id]
  key_name                = aws_key_pair.deployer.key_name
  ami_id                  = "ami-03972092c42e8c0ca"  # Amazon Linux 2 AMI
  instance_type           = "t2.micro"
}


# SSH 
output "private_key_pem" {
  value     = tls_private_key.terr-jenk.private_key_pem
  sensitive = true
}

# output "jenkins_public_ip" {
#   value = aws_instance.jenkins-machine.public_ip
# }


output "jenkins_public_ip" {
  value = module.jenkins_ec2.jenkins_public_ip
}