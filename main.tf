provider "aws" {
  region = "ap-south-1"
}

# Use your existing VPC and Subnet IDs
variable "vpc_id" {
  description = "The ID of the VPC"
  default     = "vpc-0c0a81b0f23a0bbef"  # Replace with your VPC ID
}

variable "subnet_id" {
  description = "The ID of the subnet"
  default     = "subnet-00fd9733fafc4c1ba"  # Replace with your Subnet ID
}

resource "aws_security_group" "jenkins_sg" {
  vpc_id = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "jenkins_master" {
  ami           = "ami-0f58b397bc5c1f2e8"  # Amazon Ubuntu AMI
  instance_type = "t3.medium"
  subnet_id     = var.subnet_id
  associate_public_ip_address = true  # Assign a public IP to the instance
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]  # Use vpc_security_group_ids instead of security_group_ids
  key_name      = "mumadvento"

  tags = {
    Name = "Jenkins-Master"
  }

  user_data = <<-EOF
                #!/bin/bash
                # Update package list
                sudo apt-get update
                # Install Java (OpenJDK 11)
                sudo apt-get install -y openjdk-11-jdk
                # Add Jenkins repository and key
                curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee \
                /usr/share/keyrings/jenkins-keyring.asc > /dev/null
                echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | sudo tee \
                /etc/apt/sources.list.d/jenkins.list > /dev/null
                # Update package list again
                sudo apt-get update
                # Install Jenkins
                sudo apt-get install -y jenkins
                # Start Jenkins service
                sudo systemctl start jenkins
                sudo systemctl enable jenkins
                EOF
}

resource "aws_instance" "jenkins_slave" {
  ami           = "ami-0f58b397bc5c1f2e8"  # Amazon Ubuntu AMI
  instance_type = "t3.medium"
  subnet_id     = var.subnet_id
  associate_public_ip_address = true  # Assign a public IP to the instance
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]  # Use vpc_security_group_ids instead of security_group_ids
  key_name      = "mumadvento"

  tags = {
    Name = "Jenkins-Slave"
  }

  user_data = <<-EOF
              #!/bin/bash
              # Update package list
              sudo apt-get update
              # Install Java (OpenJDK 11)
              sudo apt-get install -y openjdk-11-jdk
              # Install Docker
              sudo apt-get install -y docker.io
              sudo systemctl start docker
              sudo systemctl enable docker
              # Install Maven
              sudo apt-get install -y maven
              EOF
}

output "jenkins_master_public_ip" {
  value = aws_instance.jenkins_master.public_ip
}
