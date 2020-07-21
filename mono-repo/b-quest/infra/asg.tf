module "asg" {
  source = "joshua-bradley/tfc-merge-n-migrate/local-modules/demo-aws-asg/module"

  prefix = "hc-jb-asg-test"

  # asg specific paramters
  max_size            = 1
  min_size            = 1
  desired_capcaity    = 1
  health_check_type   = "EC2"
  vpc_zone_identifier = module.vpc.public_subnets
  tags_as_map = {
    "Name"  = "hc-josh-asg"
    "owner" = "hc-joshua"
    "TTL"   = "24"
  }

  #lc specific parameters
  associate_public_ip_address = true
  instance_type               = t3.micro
  key_name                    = "hc-jb-2020"
}
