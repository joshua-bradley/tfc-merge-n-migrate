module "asg" {

  source  = "app.terraform.io/jb-io/asg/aws//modules"
  version = "1.0.7"

  prefix = "hc-jb-asg-test"

  # asg specific paramters
  max_size            = 3
  min_size            = 1
  desired_capacity    = 2
  health_check_type   = "EC2"
  vpc_zone_identifier = module.vpc.public_subnets
  tags_as_map = {
    "Name"  = "hc-josh-asg"
    "owner" = "hc-joshua"
    "TTL"   = "-1"
  }

  #lc specific parameters
  associate_public_ip_address = true
  instance_type               = "t3.micro"
  key_name                    = "hc-jb-2020"
  security_groups             = ["sg-0c33716a4ad1d97b0"]
}
