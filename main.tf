# Remote Backend
terraform {
  backend "s3" {
    bucket = "infrastatefile.learntechnology.cloud"
    key    = "ami/terraform.tfstate"
    region = "us-east-1"
  }
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

# Fetch the latest CentOS AMI
data "aws_ami" "ami" {
  most_recent = true
  name_regex  = "Centos-8-DevOps-Practice"
  owners      = ["973714476881"]
}

# Fetch the security group
data "aws_security_group" "sg" {
  name = "allow-all"
}

# Create an EC2 instance
resource "aws_instance" "ec2" {
  instance_type          = "t3.small"
  ami                    = data.aws_ami.ami.image_id
  vpc_security_group_ids = [data.aws_security_group.sg.id]
  tags = {
    Name        = "roboshop-instance"
    Environment = "DevOps"
    Purpose     = "AMI Creation"
  }
}

# Install required software on the instance
resource "null_resource" "provisioner" {
  provisioner "remote-exec" {
    connection {
      type     = "ssh"
      user     = "root"
      password = var.root_user_password
      host     = aws_instance.ec2.private_ip
    }
    inline = [
      "sudo yum update -y &> /tmp/userdata.log",
      "sudo yum install epel-release -y &>> /tmp/userdata.log",
      "sudo yum install ansible python3.12-pip -y &>> /tmp/userdata.log",
      "sudo pip3.12 install botocore boto3 &>> /tmp/userdata.log",
      "sudo yum install bash-completion -y &>> /tmp/userdata.log",
      "sudo dnf module disable nodejs -y &>> /tmp/userdata.log",
      "sudo dnf module enable nodejs:18 -y &>> /tmp/userdata.log",
      "sudo yum install nodejs -y &>> /tmp/userdata.log",
      "sudo dnf module disable maven -y &>> /tmp/userdata.log",
      "sudo dnf module enable maven:3.8 -y &>> /tmp/userdata.log",
      "sudo yum install java-17-openjdk maven -y &>> /tmp/userdata.log",
      "sudo yum install python36 gcc python3-devel -y &>> /tmp/userdata.log",
      "sudo yum install nginx -y &>> /tmp/userdata.log"
    ]
  }
}

# Create an AMI from the instance
resource "aws_ami_from_instance" "ami" {
  depends_on         = [null_resource.provisioner]
  name               = "roboshop-ami-v1"
  source_instance_id = aws_instance.ec2.id
  tags               = { Name = "roboshop-ami-v1" }
}
