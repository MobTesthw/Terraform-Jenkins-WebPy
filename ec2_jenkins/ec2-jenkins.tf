# modules/jenkins-ec2.tf

# variable "vpc_id" {}

#variable "ec2_jenkins_ami" {}
#variable "ec2_jenkins_instance_type" {}



variable "subnet_id" {}
variable "vpc_security_group_ids" {}
variable "key_name" {}
  variable "ami" {}
  variable "instance_type" {}

resource "aws_instance" "jenkins-machine" {
  ami                    = var.ami
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = var.vpc_security_group_ids
  key_name               = var.key_name

  tags = {
    Name = "Jenkins-Server"
  }

  # user_data = file("${path.module}/jenkins-install.sh")
  user_data = file("${path.module}/jenkins-install-config.sh")                 <-------------------------------Initilize script
}

# Exit variable for IP Jenkins
#output "aws-jenkins-machine" {
#  value = aws_instance.jenkins-machine
#}

output "jenkins_public_ip" {
  value = aws_instance.jenkins-machine.public_ip
}
