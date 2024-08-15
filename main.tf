provider "aws" {
  region = "us-east-1"  # Укажите ваш регион
}

module "networking" {
  source               = "./networking"
  vpc_cidr             = var.vpc_cidr
  vpc_name             = var.vpc_name
  cidr_public_subnet   = var.cidr_public_subnet
  eu_availability_zone = var.eu_availability_zone
  cidr_private_subnet  = var.cidr_private_subnet
} 



# Create pub key 
resource "tls_private_key" "proj-1" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
# Add key pair
resource "aws_key_pair" "deployer" {
  key_name   = "my-key"
  public_key = tls_private_key.proj-1.public_key_openssh
}



# # EC2 for Jenkins
# resource "aws_instance" "jenkins-machine" {
#   ami           = "ami-03972092c42e8c0ca"  # Amazon Linux 2 AMI (в регионе us-east-1)
#   instance_type = "t2.micro"               # Free Tier
#   subnet_id     = aws_subnet.proj-1.id
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


  vpc_id                  = aws_vpc.proj-1.id
  subnet_id               = aws_subnet.proj-1.id
  vpc_security_group_ids  = [aws_security_group.jenkins_sg.id]
  key_name                = aws_key_pair.deployer.key_name
  ami_id                  = "ami-03972092c42e8c0ca"  # Amazon Linux 2 AMI
  instance_type           = "t2.micro"
}


# SSH 
output "private_key_pem" {
  value     = tls_private_key.proj-1.private_key_pem
  sensitive = true
}

# output "jenkins_public_ip" {
#   value = aws_instance.jenkins-machine.public_ip
# }


output "jenkins_public_ip" {
  value = module.jenkins_ec2.jenkins_public_ip
}