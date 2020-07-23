# Outputs file
output "catapp_url" {
  # value = "http://${aws_eip.hashiapp.public_dns}"
  value = "${aws_eip.hashiapp.*.public_dns}"
}
