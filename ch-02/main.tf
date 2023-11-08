provider "aws" {
  region = "us-west-1"
}

resource "aws_launch_configuration" "example" {
  image_id      = "ami-0cbd40f694b804622"
  instance_type = "t2.micro"
  # The vpc_security_group_ids parameter is set to the ID of the security group created by the module.
  security_groups = [aws_security_group.instance.id]
  # The <<-EOF and EOF are Terraform’s heredoc syntax, which allows you to create
  # multiline strings without having to insert \n characters all over the plac
  user_data = <<-EOF
                #!/bin/bash
                echo "Hello, World" > index.html
                nohup busybox httpd -f -p ${var.server_port} &
                EOF

  # Required when using a launch configuration with an auto scaling group.
  lifecycle {
    create_before_destroy = true
  }

}
resource "aws_autoscaling_group" "example" {
  launch_configuration = aws_launch_configuration.example.name
  vpc_zone_identifier  = data.aws_subnets.default.ids
  min_size             = 2
  max_size             = 10
  tag {
    key                 = "Name"
    value               = "terraform-asg-example"
    propagate_at_launch = true
  }
}

resource "aws_security_group" "instance" {
  name = "terraform-example-instance"
  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

variable "server_port" {
  description = "The port the server will use for HTTP requests"
  type        = number
  default     = 8080
}

# instead of having to manually poke around the console to find the IP address of the instance,
# you can use Terraform’s output command to print the value of the public_ip attribute
output "public_ip" {
  value       = aws_instance.example.public_ip
  description = "The public IP address of the web server"
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc_id"
    values = [data.aws_vpc.default.id]
  }
}
