vpc_cidr             = "10.0.0.0/16"

vpc_name             = "proj-terrafrom-jenkins-web-py"

#For Jenkins server
vpc_subnetA          = "10.0.128.0/24"
availability_zoneA    = "us-east-1a"

# For deploy HA servers
vpc_subnet_depl_A          = "10.0.1.0/24"
availability_zone_depl_A    = "us-east-1a"        #"eu-west-1"
vpc_subnet_depl_B          = "10.0.2.0/24"
availability_zone_depl_B    = "us-east-1b"      #"eu-west-2"

#EC2-Jenkins
ec2_jenkins_ami           = "ami-03972092c42e8c0ca"  # Amazon Linux 2 AMI
ec2_jenkins_instance_type    = "t2.micro"

#EC2-Deployment                
ec2_depl_ami             = "ami-06878d265978313ca"
ec2_depl_instance_type      = "t2.micro"

# cidr_public_subnet   = ["10.0.1.0/24", "10.0.2.0/24"]
# cidr_private_subnet  = ["10.0.3.0/24", "10.0.4.0/24"]
# eu_availability_zone = ["eu-west-1", "eu-west-2"]


