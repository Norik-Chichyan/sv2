terraform {
  required_version = ">= 0.12"
}
provider "aws" {
  shared_credentials_file = "/Users/Norik/AppData/terraform.rc"
  region = "us-east-1"
   
}  

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}
resource "aws_instance" "webapp" {
  ami = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  key_name = "aws-key2"
  security_groups = [aws_security_group.web-sg.name]
  #vpc_security_group_ids = [aws_security_group.basic_security.id]
  tags = {
    Name = "webapp"
  }
}
resource "local_file" "ssh_config" {
  content = templatefile("sshconfig.tmpl",
    {
      webapp-ip     = aws_instance.webapp.public_ip
    }
  )
  filename = "config"

}

resource "null_resource" "cp_ssh_file" {
  provisioner "local-exec" {
    command = "cp config ~/.ssh/config"
  }

  depends_on = [ aws_instance.webapp ]
}


resource "null_resource" "ansible-run" {
  provisioner "local-exec" {
    command = "ansible-playbook -i inventory web-app.yml"
  }
  depends_on = [
    null_resource.cp_ssh_file,
    aws_instance.webapp
  ]
}
