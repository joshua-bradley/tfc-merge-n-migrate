terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "jb-io"

    workspaces {
      name = "test-combined"
    }
  }
}
