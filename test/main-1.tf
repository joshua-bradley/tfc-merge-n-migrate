# provider "aws" {
#   version = "~> 2.0"
#   region  = var.region
# }

resource aws_vpc "hashiapp" {
  cidr_block           = var.address_space
  enable_dns_hostnames = true

  tags = {
    name = "${var.app-pre}-vpc"
  }
}

resource aws_subnet "hashiapp" {
  vpc_id     = aws_vpc.hashiapp.id
  cidr_block = var.subnet_prefix

  tags = {
    name = "${var.app-pre}-subnet"
  }
}

resource aws_security_group "hashiapp" {
  name = "${var.app-pre}-security-group"

  vpc_id = aws_vpc.hashiapp.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
    prefix_list_ids = []
  }

  tags = {
    Name = "${var.app-pre}-security-group"
  }
}

resource random_id "app-server-id" {
  prefix      = "${var.app-pre}-hashiapp-"
  byte_length = 8
}

resource aws_internet_gateway "hashiapp" {
  vpc_id = aws_vpc.hashiapp.id

  tags = {
    Name = "${var.app-pre}-internet-gateway"
  }
}

resource aws_route_table "hashiapp" {
  vpc_id = aws_vpc.hashiapp.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.hashiapp.id
  }
}

resource aws_route_table_association "hashiapp" {
  subnet_id      = aws_subnet.hashiapp.id
  route_table_id = aws_route_table.hashiapp.id
}

data aws_ami "ubuntu" {
  most_recent = true

  filter {
    name = "name"
    #values = ["ubuntu/images/hvm-ssd/ubuntu-disco-19.04-amd64-server-*"]
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_eip" "hashiapp" {
  count = var.instance_count

  instance = aws_instance.hashiapp[count.index].id
  vpc      = true
}

resource "aws_eip_association" "hashiapp" {
  count = var.instance_count

  instance_id   = aws_instance.hashiapp[count.index].id
  allocation_id = aws_eip.hashiapp[count.index].id
}

resource aws_instance "hashiapp" {
  count = var.instance_count

  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.hashiapp.key_name
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.hashiapp.id
  vpc_security_group_ids      = [aws_security_group.hashiapp.id]

  tags = {
    Name  = "${var.app-pre}-hashiapp-instance"
    ttl   = "-1"
    Owner = "jbradley@hashicorp.com"
  }
}

# We're using a little trick here so we can run the provisioner without
# destroying the VM. Do not do this in production.

# If you need ongoing management (Day N) of your virtual machines a tool such
# as Chef or Puppet is a better choice. These tools track the state of
# individual files and can keep them in the correct configuration.

# Here we do the following steps:
# Sync everything in files/ to the remote VM.
# Set up some environment variables for our script.
# Add execute permissions to our scripts.
# Run the deploy_app.sh script.
resource "null_resource" "configure-cat-app" {
  depends_on = [aws_eip_association.hashiapp]

  count = var.instance_count

  triggers = {
    build_number = timestamp()
  }

  provisioner "file" {
    source      = "files/"
    destination = "/home/ubuntu/"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = tls_private_key.hashiapp.private_key_pem
      host        = aws_eip.hashiapp[count.index].public_ip
    }
  }

  provisioner "remote-exec" {
    inline = [
      "sudo add-apt-repository universe",
      "sudo apt -y update",
      "sudo apt -y install apache2",
      "sudo systemctl start apache2",
      "sudo chown -R ubuntu:ubuntu /var/www/html",
      "chmod +x *.sh",
      "PLACEHOLDER=${var.placeholder} WIDTH=${var.width} HEIGHT=${var.height} PREFIX=${var.app-pre} ./deploy_app.sh",
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = tls_private_key.hashiapp.private_key_pem
      host        = aws_eip.hashiapp[count.index].public_ip
    }
  }
}

resource tls_private_key "hashiapp" {
  algorithm = "RSA"
}

locals {
  private_key_filename = "${var.app-pre}-ssh-key.pem"
}

resource aws_key_pair "hashiapp" {
  key_name   = local.private_key_filename
  public_key = tls_private_key.hashiapp.public_key_openssh
}
