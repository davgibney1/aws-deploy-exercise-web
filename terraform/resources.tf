## the infrastructure for the 'hola_mundo' cicd exercise
## tf version 0.10.x
### creating a VPC should be defined by another repo of code.  So this project
### assumes you already have a private VPC.  This project assumes that you have
### several other kinds of resources already defined, such as the following:
### an S3 bucket, a non-default private VPC, private subnets, an SSH key-pair...
### Please see the 'Variables' section and change values as necessary.

#####################
##### Variables #####
#####################

variable "region" {
  default = "us-west-2"
}

# a terraform "plan/apply" will prompt for your AWS credentials (or use aws-vault)
variable "access_key" {}
variable "secret_key" {}

# define an s3 bucket to be used for this project
variable "hola_mundo_s3_bucket" {
  type    = "string"
  default = "hola_mundo_cicd_2017_pdx"
}

# define a TLS certificate for use by the load balancer 
#variable "hola_mundo_elb_certificate" {
	#default = "arn:aws:iam::123456789012:server-certificate/certName"
#}
## commented this out; let's create one instead.  See below, the section after "Provider"

# define the VPC ID of a VPC to use
variable "hola_mundo_vpc" {
	default = "vpc-1111aaaa"
}

# define the VPC's subnets to use (you should want at least two, for fault tolerance)
variable "subnet_1" {
	default = "subnet-2222bbbb"
}

variable "subnet_2" {
	default = "subnet-3333cccc"
}

# define the ec2 instance's key pair to use (you should already have created one)
variable "ec2_ssh_key_pair_name" {
	default = "user1_key_master_pdx"
}

# IP addresses (CIDR format) to allow access to the instances / ELB
variable "workstation_ip" {
	default "10.10.10.1/32"
}

variable "office_nat_ip" {
	default "172.16.32.64/32"
}

# define the locations of files with "user data" for ec2 instances
data "template_file_nginx" "user_data_nginx" {
  template = "${file("${path.module}/userdata_nginx.tpl")}"
}

data "template_file_apache" "user_data_apache" {
  template = "${file("${path.module}/userdata_apache.tpl")}"
}


####################
##### Provider #####
####################

provider "aws" {
  #alias      = "hola_mundo"
  #profile    = "hola_mundo"
  access_key  = "${var.access_key}"
  secret_key  = "${var.secret_key}"
  region      = "${var.region}"
}


###################
### Certificate ###
###################

data "aws_iam_server_certificate" "hola_mundo_domain" {
  name_prefix = "hola_mundo_domain_2017.org"
  latest      = true
}


###########
### AMI ###
###########

# define an ubuntu AMI - let's use the latest 16.04 release
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]  # Canonical's account
}


############################
### IAM Instance Profile ###
############################

resource "aws_iam_instance_profile" "hola_mundo_profile" {
  name  = "hola_mundo_profile"
  role = "${aws_iam_role.hola_mundo_role.name}"
}

resource "aws_iam_role" "hola_mundo_role" {
  name = "hola_mundo_role"
  path = "/"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "HolaMundoEc2"
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow"
        }
    ]
}
EOF
}


###############
##### ELB #####
###############

resource "aws_elb" "hola_mundo_elb" {
  name               = "hola_mundo_elb"
  #availability_zones = ["us-west-2a", "us-west-2b"]
  subnets			 = [ "${var.subnet_1}", "${var.subnet_2}"]
  security_groups    = [ "${aws_security_group.hola_mundo_elb_sg.id}" ]

  access_logs {
    bucket        = "${var.hola_mundo_s3_bucket}"
    bucket_prefix = "elb_logs"
    interval      = 60
  }

  listener {
    instance_port     = 8900
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  listener {
    instance_port      = 8900
    instance_protocol  = "http"
    lb_port            = 443
    lb_protocol        = "https"
    #ssl_certificate_id = "${var.hola_mundo_elb_certificate}"
    ssl_certificate_id = "${data.aws_iam_server_certificate.hola_mundo_domain_2017.arn}"
  }

  health_check {
    healthy_threshold   = 4
    unhealthy_threshold = 3
    timeout             = 5
    target              = "HTTP:8900/"
    interval            = 25
  }

  instances                   = ["${aws_instance.web_nginx_1.id}", "${aws_instance.web_apache_1.id}", "${aws_instance.web_apache_2.id}"]
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags {
    Name    = "hola_mundo_elb"
    env     = "dev"
    owner   = "user1"
    project = "hola_mundo"
  }
}


#####################
### EC2 Instances ###
#####################

# let's define one nginx web server, and two apache web servers

resource "aws_instance" "web_nginx_1" {
  ami                  = "${data.aws_ami.ubuntu.id}"
  instance_type        = "t2.micro"
  subnet_id		       = "${var.subnet_1}"
  key_name 		       = "${var.ec2_ssh_key_pair_name}"
  security_groups      = [ "${aws_security_group.hola_mundo_ec2_sg.id}" ]
  user_data            = "${data.template_file_nginx.user_data.rendered}"
  iam_instance_profile = "${aws_iam_instance_profile.hola_mundo_profile.id}"

  tags {
    Name    = "hola_mundo_nginx_1"
    env     = "dev"
    owner   = "user1"
    project = "hola_mundo"
  }
}

resource "aws_instance" "web_apache_1" {
  ami                  = "${data.aws_ami.ubuntu.id}"
  instance_type        = "t2.micro"
  subnet_id		       = "${var.subnet_2}"
  key_name 		       = "${var.ec2_ssh_key_pair_name}"
  security_groups      = [ "${aws_security_group.hola_mundo_ec2_sg.id}" ]
  user_data            = "${data.template_file_apache.user_data.rendered}"
  iam_instance_profile = "${aws_iam_instance_profile.hola_mundo_profile.id}"

  tags {
    Name    = "hola_mundo_apache_1"
    env     = "dev"
    owner   = "user1"
    project = "hola_mundo"
  }
}

resource "aws_instance" "web_apache_2" {
  ami                  = "${data.aws_ami.ubuntu.id}"
  instance_type        = "t2.micro"
  subnet_id		       = "${var.subnet_2}"
  key_name 		       = "${var.ec2_ssh_key_pair_name}"
  security_groups      = [ "${aws_security_group.hola_mundo_ec2_sg.id}" ]
  user_data            = "${data.template_file_apache.user_data.rendered}"
  iam_instance_profile = "${aws_iam_instance_profile.hola_mundo_profile.id}"

  tags {
    Name    = "hola_mundo_apache_2"
    env     = "dev"
    owner   = "user1"
    project = "hola_mundo"
  }
}


#######################
### Security Groups ###
#######################

resource "aws_security_group" "hola_mundo_ec2_sg" {
  name        = "hola_mundo_ec2_sg"
  description = "Rules for the hola mundo EC2 instances"
  vpc_id      = "${var.hola_mundo_vpc}"

  ingress {
    from_port   = 0
    to_port     = 22
    protocol    = "ssh"
    cidr_blocks = [ "${var.office_nat_ip}", "${var.workstation_ip}" ]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "hola_mundo_elb_sg" {
  name        = "hola_mundo_elb_sg"
  description = "Rules for the hola mundo ELB"
  vpc_id      = "${var.hola_mundo_vpc}"

  ingress {
    from_port   = 0
    to_port     = 80
    protocol    = "http"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port   = 0
    to_port     = 443
    protocol    = "https"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}
