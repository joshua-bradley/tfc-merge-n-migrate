variable "region" {
  default = "us-west-2"
}
variable "prefix" {
  description = "This prefix will be included in the name of most resources."
  default     = "hc-jb"
}

variable "standard_tags" {
  description = "Standard tags to set on the Instances in the ASG"
  type        = map(string)
  default = {
    "project-name" = "hc-jb-zoominfo"
    "owner"        = "hc-joshua"
    "TTL"          = "6"
  }
}
