provider "aws" {
  version = ">= 2.50.0"
  region  = var.region
}

# find the available zones in the region where ec2 resources may deployed
data "aws_availability_zones" "available" {
  state = "available"
}

resource "random_id" "r_id" {
  byte_length = 4
}
