variable "aws_region" {
  default = "us-east-1"
}

variable "aws_amis" {
  default = {
    us-east-1 = "ami-96494c80"
    us-west-2 = "ami-4f00e32f"
    us-west-1 = "ami-a8aedfc8"
  }
}

variable "inbound_cidr" {
  default = "172.16.0.0/16"
}

variable "availability_zones" {
  default = "us-east-1b,us-east-1c,us-east-1d,us-east-1e"
}

variable "instance_type" {
  default = "t2.micro"

  description = "The size of the cluster nodes, e.g: t2.large. Note that OpenShift will not run on anything smaller than t2.large"
  description = "AWS instance type"
}

variable "key_name" {
  description = "pwin1"
}

provider "aws" {
  region = "${var.aws_region}"
}

variable "aws_subnet_cidr_block" {
  default = "172.16.0.0/18,172.16.64.0/18,172.16.128.0/18"
}
