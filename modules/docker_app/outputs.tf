output "container_name" {
  description = "Nazwa kontenera"
  value       = docker_container.app.name
}

output "container_id" {
  description = "Short container ID"
  value       = substr(docker_container.app.id, 0, 12)
}

output "app_url" {
  description = "Health URL"
  value       = "http://localhost:${var.host_port}/health"
}

output "volume_name" {
  description = "Nazwa volume"
  value       = docker_volume.data.name
}
