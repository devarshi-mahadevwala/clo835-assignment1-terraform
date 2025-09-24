terraform {
  required_providers {
    aws = { source = "hashicorp/aws" }
    tls = { source = "hashicorp/tls" }
    local = { source = "hashicorp/local" }
  }
  required_version = ">= 1.2"
}
