terraform {
  required_version = ">= 1.0"
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.6"
    }
  }
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}

module "backend" {
  source = "./modules/docker_app"

  app_name    = "backend"
  app_version = "v0.2.0"
  app_port    = 3000
  host_port   = 3000
  node_env    = "production"
}

output "app_url" {
  value = module.backend.app_url
}

output "container_name" {
  value = module.backend.container_name
}
