terraform {
  required_version = ">= 1.0"

  required_providers {
    minikube = {
      source  = "scott-the-programmer/minikube"
      version = "0.6.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.1.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.2.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "4.0.4"
    }
  }
}

provider "minikube" {}

provider "null" {
  # Config empty necessary
}

provider "local" {
  # Config empty necessary
}