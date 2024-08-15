variable "vpc_cidr" {}
variable "vpc_subnetA" {}
variable "vpc_name"  {}
variable "availability_zoneA" {}

variable "ec2_jenkins_ami" {}
variable "ec2_jenkins_instance_type" {}

# For deploy HA servers
variable "vpc_subnet_depl_A"  			{}
variable "availability_zone_depl_A" 	{}
variable "vpc_subnet_depl_B"			{}
variable "availability_zone_depl_B"  	{}

variable "ec2_depl_ami"  	{}
variable "ec2_depl_instance_type"  	{}


provider "aws" {
  region = "us-east-1"  # Укажите ваш регион
}


# Create pub key 
resource "tls_private_key" "proj_1" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
# Add key pair
resource "aws_key_pair" "deployer" {
  key_name   = "my-key"
  public_key = tls_private_key.proj_1.public_key_openssh
}

module "networking" {
  source               = "./networking"
  vpc_cidr             = var.vpc_cidr
  vpc_name             = var.vpc_name
  vpc_subnet           = var.vpc_subnetA
  availability_zone    = var.availability_zoneA
  
  #For HA deploy Servers
  vpc_subnet_depl_A =  var.vpc_subnet_depl_A          
  availability_zone_depl_A  =  var.availability_zone_depl_A   
  vpc_subnet_depl_B =  var.vpc_subnet_depl_B          
  availability_zone_depl_B  =  var.availability_zone_depl_B  

  ec2_depl_ami             = var.ec2_depl_ami
  ec2_depl_instance_type   = var.ec2_depl_instance_type
  key_name                = aws_key_pair.deployer.key_name
     




} 






module "ec2_jenkins" {
  source = "./ec2_jenkins"
  # vpc_id                  = aws_vpc.proj_1.id
  subnet_id               = module.networking.subnet_jenkins
  vpc_security_group_ids  = [module.networking.security_group_jenkins_id]
  key_name                = aws_key_pair.deployer.key_name
  ami                     = var.ec2_jenkins_ami
  instance_type           = var.ec2_jenkins_instance_type
}


# SSH 
output "private_key_pem" {
  value     = tls_private_key.proj_1.private_key_pem
  sensitive = true
}

# output "jenkins_public_ip" {
#   value = aws_instance.jenkins-machine.public_ip
# }


output "jenkins_public_ip" {
  value = module.ec2_jenkins.jenkins_public_ip
}



# terraform output -raw private_key_pem > key.pem
# ssh -i key.pem ec2-user@44.202.212.136