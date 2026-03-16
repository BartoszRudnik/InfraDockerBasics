resource "docker_image" "app" {
  name         = "ghcr.io/bartoszrudnik/infradockerbasics/backend:${var.app_version}"
  keep_locally = false
}

resource "docker_volume" "data" {
  name = "${var.app_name}-data"
}

resource "docker_container" "app" {
  name    = var.app_name
  image   = docker_image.app.image_id
  restart = "unless-stopped"

  ports {
    internal = var.app_port
    external = var.host_port
    ip       = "0.0.0.0"
  }

  volumes {
    volume_name    = docker_volume.data.name
    container_path = "/app/data"
  }

  env = [
    "NODE_ENV=${var.node_env}",
    "PORT=${var.app_port}",
    "APP_VERSION=${var.app_version}",
  ]

  healthcheck {
    test         = ["CMD", "wget", "-qO-", "http://localhost:${var.app_port}/health"]
    interval     = "30s"
    timeout      = "5s"
    start_period = "10s"
    retries      = 3
  }

  lifecycle {
    ignore_changes = [image]
  }
}
