# Создание VPC
resource "aws_vpc" "proj-1" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = var.vpc_name
  }
}

# Создание Subnet
resource "aws_subnet" "proj-1" {
  vpc_id            = aws_vpc.proj-1.id
  cidr_block        = var.vpc_subnetA
  availability_zone = var.availability_zone
  
  map_public_ip_on_launch = true		#Try to map public IP

  tags = {
    Name = "dev-proj-subnet"
  }
}





# Создание Internet Gateway
resource "aws_internet_gateway" "proj-1" {
  vpc_id = aws_vpc.proj-1.id

  tags = {
    Name = "dev-proj-igw"
  }
}

# Создание Route Table
resource "aws_route_table" "proj-1" {
  vpc_id = aws_vpc.proj-1.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.proj-1.id
  }

  tags = {
    Name = "dev-proj-route-table"
  }
}

# Ассоциация Route Table с Subnet
resource "aws_route_table_association" "proj-1" {
  subnet_id      = aws_subnet.proj-1.id
  route_table_id = aws_route_table.proj-1.id
}

# Security Group for Jenkins
resource "aws_security_group" "jenkins_sg" {
  vpc_id = aws_vpc.proj-1.id

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
output "security_group_id" {
  value = aws_security_group.jenkins_sg.id
}
