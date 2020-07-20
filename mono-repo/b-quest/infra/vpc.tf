module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${var.prefix}-vpc-${random_id.r_id.hex}"
  cidr = "10.0.0.0/16"

  azs = [
    data.aws_availability_zones.available.names[0]
  ]
  private_subnets = ["10.0.1.0/24"]
  public_subnets  = ["10.0.101.0/24"]

  enable_nat_gateway = true
  #   enable_vpn_gateway = true
  #   map_public_ip_on_launch = true

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = var.standard_tags
}
