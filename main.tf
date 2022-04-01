terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 3.72"
    }
  }
  required_version = ">= 0.15"
}

provider "aws" {
  profile = "default"
  region = "us-east-1"
}

resource "aws_key_pair" "kmg" {
  key_name   = "kmg_aws_key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC4pcIPJ3wfR3XDPKWxuII1ma4JFZOL3hTAJKPZtCIAS1upxLCiZ3kajiizMY1CVV49mSkTBTMaVCZANmxUgxomS6p9QNM8+H0AozGyb7rrbV7mgSjomtpgG/MxoIRDYR1jIRc106HW9EtecMpEZvoySvnPaFR4vApFvXrwXCmWnT9/MvT+VOlbjAnO4Y8ABV0CTseolcXD7rkS2wt1zw+oxEfV2fa0ChD7foJOO5fVbag8sVOGZYmXPHmSHscXn1do7jiAthhG5uF+GGdxOS2va930gOCBMlab6UvAU8z9t7HsEnMGOPpWi/npzTrRK3hyfsIR2wLPLnjj+2MXoaVT kmg@kmg11.nyc.corp.google.com"
}

resource "aws_route53_zone" "kaf" {
  name = "kiwiairforce.com."
}

resource "aws_route53_zone" "kaf_enclave" {
  name = "enclave.kiwiairforce.com"
  tags = {
    Name = "NitroHttpServerTest"
  }
}

resource "aws_route53_record" "kaf_enclave_ns" {
  zone_id = aws_route53_zone.kaf.zone_id
  name    = "enclave.kiwiairforce.com"
  type    = "NS"
  ttl     = "30"
  records = aws_route53_zone.kaf_enclave.name_servers
}

resource "aws_route53_record" "kaf_enclave_a" {
  zone_id = aws_route53_zone.kaf_enclave.zone_id
  name    = "enclave.kiwiairforce.com"
  type    = "A"
  ttl     = "30"
  records = [aws_instance.nitro_server.public_ip]
}

resource "aws_route53_record" "kaf_enclave_builder_a" {
  zone_id = aws_route53_zone.kaf_enclave.zone_id
  name    = "builder.enclave.kiwiairforce.com"
  type    = "A"
  ttl     = "30"
  records = [aws_instance.builder.public_ip]
}

resource "aws_ecr_repository" "nitro_test_repository" {
  name = "nitro_test_server"
}

resource "aws_vpc" "nitro_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "NitroHttpServerTest"
  }
}

resource "aws_internet_gateway" "nitro_internet_gateway" {
  vpc_id = aws_vpc.nitro_vpc.id
  tags = {
    Name = "NitroHttpServerTest"
  }
}

resource "aws_subnet" "nitro_pub_subnet" {
  vpc_id = aws_vpc.nitro_vpc.id
  cidr_block = "10.0.1.0/24"
  tags = {
    Name = "NitroHttpServerTest-Public"
  }
}

resource "aws_route_table" "nitro_public_route" {
  vpc_id = aws_vpc.nitro_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.nitro_internet_gateway.id
  }
}

resource "aws_route_table_association" "nitro_route_table_assn" {
  subnet_id      = aws_subnet.nitro_pub_subnet.id
  route_table_id = aws_route_table.nitro_public_route.id
}

resource "aws_default_security_group" "nitro_server_sg" {
  vpc_id      = aws_vpc.nitro_vpc.id
  tags = {
    Name = "NitroHttpServer-sg"
  }
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
  }
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
  }
  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
  }
  egress {
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}


data "template_file" "nitro_server" {
  template = file("${path.module}/nitro_startup.sh")
  vars = {}
}

data "template_file" "builder" {
  template = file("${path.module}/builder_startup.sh")
  vars = {}
}

resource "aws_iam_role" "nitro_ec2_role" {
  name               = "nitroec2-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": ["ec2.amazonaws.com"]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "nitro_ec2_role_policy" {
  name = "nitroec2-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ecr:*",
          "s3:*",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_instance_profile" "nitro_server_profile" {
  name = "nitroec2-instance-profile"
  role = aws_iam_role.nitro_ec2_role.name
}

resource "aws_iam_policy_attachment" "attach" {
  name       = "nitroec2-attach"
  roles      = ["${aws_iam_role.nitro_ec2_role.name}"]
  policy_arn = "${aws_iam_policy.nitro_ec2_role_policy.arn}"
}

resource "aws_instance" "nitro_server" {
  ami = "ami-0c02fb55956c7d316"
  instance_type = "c5.xlarge"
  user_data = data.template_file.nitro_server.rendered
  enclave_options {
    enabled = true
  }
  associate_public_ip_address = true
  subnet_id = aws_subnet.nitro_pub_subnet.id
  key_name = aws_key_pair.kmg.id
  iam_instance_profile = aws_iam_instance_profile.nitro_server_profile.name
  tags = {
    Name = "NitroHttpServerTest-server"
  }
}

resource "aws_instance" "builder" {
  ami = "ami-0c02fb55956c7d316"
  instance_type = "c5.xlarge"
  user_data = data.template_file.builder.rendered
  enclave_options {
    enabled = true
  }
  associate_public_ip_address = true
  subnet_id = aws_subnet.nitro_pub_subnet.id
  key_name = aws_key_pair.kmg.id
  iam_instance_profile = aws_iam_instance_profile.nitro_server_profile.name
  tags = {
    Name = "EnclaveBuilder"
  }
}
