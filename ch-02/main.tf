provider "aws" {
  region = "us-west-1"
}

resource "aws_instance" "example" {
  ami           = "ami-0cbd40f694b804622"
  instance_type = "t2.micro"
  # The <<-EOF and EOF are Terraform’s heredoc syntax, which allows you to create
  # multiline strings without having to insert \n characters all over the plac
  user_data = <<-EOF
                #!/bin/bash
                echo "Hello, World" > index.html
                nohup busybox httpd -f -p 8080 &
                EOF
  # The user_data_replace_on_change parameter is set to true so that when you change the user_data parameter and run apply,
  # Terraform will terminate the original instance and launch a totally new one.
  user_data_replace_on_change = true
  tags = {
    Name = "terraform-example"
  }
}
