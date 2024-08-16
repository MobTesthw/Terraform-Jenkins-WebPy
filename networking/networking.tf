variable "vpc_cidr" {}
variable "vpc_subnet" {}
variable "vpc_name" {}
variable "availability_zone" {}

# For deploy HA servers
variable "vpc_subnet_depl_A"  			{}
variable "availability_zone_depl_A" 	{}
variable "vpc_subnet_depl_B"			{}
variable "availability_zone_depl_B"  	{}

variable "ec2_depl_ami"  	{}
variable "ec2_depl_instance_type"  	{}
variable "key_name" {}


# Создание VPC
resource "aws_vpc" "proj_1" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = var.vpc_name
  }
}

#---------------------------------------------Subnets----------
# Создание Subnet Jenkins
resource "aws_subnet" "proj_1_Jenkins" {
  vpc_id            = aws_vpc.proj_1.id
  cidr_block        = var.vpc_subnet
  availability_zone = var.availability_zone
  
  map_public_ip_on_launch = true		#Try to map public IP

  tags = {
    Name = "dev_proj_jenkins_subnet"
  }
}
output "subnet_jenkins" {                         # Export 
  value = aws_subnet.proj_1_Jenkins.id
}


# Subnets depl a
resource "aws_subnet" "public_a" {
  vpc_id     = aws_vpc.proj_1.id
  cidr_block = var.vpc_subnet_depl_A
  availability_zone = var.availability_zone_depl_A

  tags = {
    Name = "public_a"
  }
}
#output "subnet_depl_A" {                           # Export 
#  value = aws_subnet.public_a.id
#}



resource "aws_subnet" "public_b" {
  vpc_id     = aws_vpc.proj_1.id
  cidr_block = var.vpc_subnet_depl_B
  availability_zone = var.availability_zone_depl_B

  tags = {
    Name = "public_b"
  }
}
#output "subnet_depl_B" {                            # Export 
#  value = aws_subnet.public_b.id
#}




#---------------------------------------------Internet Gateway----------
# Создание Internet Gateway
resource "aws_internet_gateway" "proj_1" {
  vpc_id = aws_vpc.proj_1.id

  tags = {
    Name = "dev-proj-igw"
  }
}
#---------------------------------------------Route Table
# Создание Route Table
resource "aws_route_table" "proj_1" {
  vpc_id = aws_vpc.proj_1.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.proj_1.id
  }

  tags = {
    Name = "dev-proj-route-table"
  }
}


#---------------------------------------------association
# Ассоциация Route Table с Subnet
resource "aws_route_table_association" "proj_1" {
  subnet_id      = aws_subnet.proj_1_Jenkins.id
  route_table_id = aws_route_table.proj_1.id
}



resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.proj_1.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.proj_1.id
}





#---------------------------------------------Security Groupn

# Security Group for Jenkins
resource "aws_security_group" "jenkins_sg" {
  name        = "sg_jenkins"
  vpc_id = aws_vpc.proj_1.id

  # HTTP (80)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Для безопасности измените этот параметр для Production
  }

#  # HTTPS (443)
#  ingress {
#    from_port   = 443
#    to_port     = 443
#    protocol    = "tcp"
#    cidr_blocks = ["0.0.0.0/0"]  # Для безопасности измените этот параметр для Production
#  }

  # SSH (22)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Разрешает доступ по SSH отовсюду
  }

  # Jenkins (8080)
    ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Remote access to Jenkins by Public IP

    # Limitation Accroding Home assignment: •	Jenkins should be exposed to your ip address and the ranges (131.228.32.160/27 , 131.228.2.0/27)
    # cidr_blocks      = ["<my-ip-address>/32", "131.228.32.160/27", "131.228.2.0/27"]
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

# Export SG ID
output "security_group_jenkins_id" {
  value = aws_security_group.jenkins_sg.id
}

# Security Group for Deployment
resource "aws_security_group" "depl_sg" {
  name        = "sg_deploy"
  vpc_id      = aws_vpc.proj_1.id

  ingress {
    description      = "Allow http from everywhere"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    # Limitation Accroding Home assignment: •	Expose the application for specific ip ranges only (131.228.32.160/27 , 131.228.2.0/27)
    # cidr_blocks      = ["131.228.32.160/27", "131.228.2.0/27"]
  }

  ingress {
    description      = "Allow http from everywhere"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    description      = "Allow outgoing traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "my-sg"
  }
}

# Export SG ID
output "security_group_depl_id" {
  value = aws_security_group.depl_sg.id
}

#---------------------------------------------Load Balancer for Deployment
# Load Balancer  for deploymen HA:
# Load Balancer:
resource "aws_lb" "my_alb" {
  name               = "my-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.depl_sg.id]
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_b.id]
}

# Listener for Load Balancer:
resource "aws_lb_listener" "my_lb_listener" {
  load_balancer_arn = aws_lb.my_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.my_tg.arn
  }
}

# Target Group: (forward the traffic of our load balancer to the EC2 instances)
resource "aws_lb_target_group" "my_tg" {
  name     = "my-tg"
  target_type = "instance"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.proj_1.id
}



# Launch Template:
resource "aws_launch_template" "my_launch_template" {

  name = "my_launch_template"
  
  image_id = var.ec2_depl_ami                     #"ami-06878d265978313ca"
  instance_type = var.ec2_depl_instance_type      #"t2.micro"
  key_name = var.key_name     #"key-pem"                            #"ubuntu"

  tags = {
    Name = "Deploy-Server"
  }

  
  user_data = filebase64("${path.module}/server-deploy-apt-docker.sh")             <-------------------------------Initilize script

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size = 8
      volume_type = "gp2"
    }
    
  }
  network_interfaces {
    associate_public_ip_address = true
    security_groups = [aws_security_group.depl_sg.id]
  }


}

# Autoscaling Group:
resource "aws_autoscaling_group" "my_asg" {
  name                      = "my_asg"
  max_size                  = 5
  min_size                  = 2
  # health_check_type         = "ELB"    # optional - additional ELB health checks
  desired_capacity          = 2
  target_group_arns = [aws_lb_target_group.my_tg.arn]

  vpc_zone_identifier       = [aws_subnet.public_a.id, aws_subnet.public_b.id]
  
  launch_template {
    id      = aws_launch_template.my_launch_template.id
    version = "$Latest"
  }
}
# Scale-up policy: based on the CPU utilization
resource "aws_autoscaling_policy" "scale_up" {
  name                   = "scale_up"
  policy_type            = "SimpleScaling"
  autoscaling_group_name = aws_autoscaling_group.my_asg.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = "1"      # add one instance
  cooldown               = "300"    # cooldown period after scaling
}

# Scale-up cloud-watch alarm:

resource "aws_cloudwatch_metric_alarm" "scale_up_alarm" {
  alarm_name          = "scale-up-alarm"
  alarm_description   = "asg-scale-up-cpu-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "50"
  dimensions = {
    "AutoScalingGroupName" = aws_autoscaling_group.my_asg.name
  }
  actions_enabled = true
  alarm_actions   = [aws_autoscaling_policy.scale_up.arn]
}

#Scale-down policy:
resource "aws_autoscaling_policy" "scale_down" {
  name                   = "asg-scale-down"
  autoscaling_group_name = aws_autoscaling_group.my_asg.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = "-1"
  cooldown               = "300"
  policy_type            = "SimpleScaling"
}

# Scale-down cloud-watch alarm:
resource "aws_cloudwatch_metric_alarm" "scale_down_alarm" {
  alarm_name          = "asg-scale-down-alarm"
  alarm_description   = "asg-scale-down-cpu-alarm"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "30"
  dimensions = {
    "AutoScalingGroupName" = aws_autoscaling_group.my_asg.name
  }
  actions_enabled = true
  alarm_actions   = [aws_autoscaling_policy.scale_down.arn]
}