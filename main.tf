# Remote Backend
terraform {
  backend "s3" {
    bucket = "statefile.learntechnology.cloud"
    key    = "ami/terraform.tfstate"
    region = "us-east-1"
  }
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

# Take one AMI to create Instance
data "aws_ami" "ami" {
  most_recent = true
  name_regex  = "Centos-8-DevOps-Practice"
  owners      = [973714476881]
}

# Fetch the SG
data "aws_security_group" "sg" {
  name = "allow-all"
}

# Create instance
resource "aws_instance" "ec2" {
  instance_type          = "t3.small"
  ami                    = data.aws_ami.ami.image_id
  vpc_security_group_ids = [data.aws_security_group.sg.id]
  tags                   = { Name = "ami" }
}

# Install the software.
resource "null_resource" "provisioner" {
  provisioner "remote-exec" {
    connection {
      type     = "ssh"
      user     = "root"
      password = var.root_user_password
      host     = aws_instance.ec2.private_ip
    }
    inline = [
      "sudo yum install ansible python3.12-pip -y &> /tmp/userdata.log",
      "sudo pip3.12 install  botocore boto3 &>> /tmp/userdata.log",
      "sudo yum install bash-completion"
    ]
  }
}

# Create AMI
resource "aws_ami" "roboshop" {
  depends_on = [null_resource.provisioner]
  name       = "roboshop-ami"
}