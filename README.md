# Deployment Exercise in AWS - Web Servers

This is a simple exercise to demonstrate deploying a small stack of resources into AWS.  

The stack consists of three EC2 instances behind an ELB.  The hosts need to be pre-configured web servers, SSH-accessible from only two specific IP addresses and ports, accessible over the public web only through the ELB, and protected from all other access.

I got the code challenge from a friend.


## How to deploy

My code is a first draft attempt to answer the exercise requirements.


1. Install terraform.  c.f. https://www.terraform.io/intro/getting-started/install.html
2. Modify the variables in `terraform/resources.tf` so that it matches with the resources in your AWS account (such as VPC ID, Subnet IDs, EC2 SSH key pair, S3 bucket, etc)
3. `cd` into the `terraform/` directory (your cwd must be where the terraform files reside)
4. Run `terraform plan` and `terraform apply`
5. I recommend using `aws-vault` in order to safely store and use your AWS API access key.  c.f. https://github.com/99designs/aws-vault 


## Exercise requirements


Using the method of your choice, write automation to create the following web application stack. Your automation assets should be able to run without errors to provision the environment. 

 

**1.0. Create an ELB**

1.1. Listen on

1.1.1. HTTP Port 80

1.1.2. HTTPS Port 443

1.1.2.1. Terminate SSL here  

**2.0. Create 3 "t2.micro" EC2 instances**

2.1. use `ami-f009cb88`

2.1.1. uses `"ubuntu"` as user name for ssh

2.1.2. in `us-west-2` region

2.2. Two of the instances must be configured as a web server using web server software of your choice:

2.2.1. Apache, Nginx, Node.js, Tomcat, Tornado, etc.

2.3. The third instance must be configured as a web server using different software from the other 2 (e.g. if the first 2 use apache, this one uses nginx)

2.4. All 3 web servers must be configured as follows:

2.4.1. listen on port 8900 for HTTP

2.4.2. Web access logs configured to write to `/var/log/hola_mundo/accesslogs/`

2.4.3. Web servers must not be running as root

2.4.4. Web servers must return a "hello world!" type page

 

**3.0. Register all 3 EC2 web servers with ELB created in step 1**

 

**4.0. Networking:**

4.1. Your laptop should be able to ssh into the instances

4.2. Your office IP should be able to ssh into the instances

4.3. The ELB should be forwarding web requests to hosts over port 8900

4.4. Port 8900 should only be accessible by the ELB

4.5. All other host ports not specified shouldn't be accessible  



**Additional instructions:**

- Feel free to create VPCs/subnets/ssh-keys/etc as required to complete your project 

- Your submission should consist of code that runs without error, such as with chef/ansible/bash/python/cloudformation/terraform/etc



