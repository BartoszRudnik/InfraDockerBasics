resource "azurerm_resource_group" "main" {
  name     = "rg-infra-docker-basics"
  location = "North Europe"
}

resource "azurerm_container_registry" "acr" {
  name                = "acrinfradockerbasics"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Basic"
  admin_enabled       = false
}

resource "azurerm_log_analytics_workspace" "main" {
  name                = "log-infra-docker-basics"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_container_app_environment" "main" {
  name                       = "cae-infra-docker-basics"
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  lifecycle {
    ignore_changes = [
      log_analytics_workspace_id,
    ]
  }
}

resource "azurerm_container_app" "backend" {
  name                         = "ca-backend"
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = azurerm_resource_group.main.name
  revision_mode                = "Single"

  template {
    container {
      name   = "backend"
      image  = "ghcr.io/bartoszrudnik/infradockerbasics/backend:main"
      cpu    = 0.25
      memory = "0.5Gi"

      env {
        name  = "NODE_ENV"
        value = "production"
      }

      env {
        name  = "PORT"
        value = "3000"
      }
    }

    min_replicas = 0
    max_replicas = 3
  }

  ingress {
    external_enabled = true
    target_port      = 3000

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  lifecycle {
    ignore_changes = [
      container_app_environment_id,
      template[0].container[0].ephemeral_storage,
      tags,
    ]
  }
}

resource "azurerm_container_app" "staging" {
  name                         = "ca-backend-staging"
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = azurerm_resource_group.main.name
  revision_mode                = "Single"

  ingress {
    external_enabled           = true
    target_port                = 3000
    transport                  = "auto"
    allow_insecure_connections = false

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  template {
    min_replicas = 0
    max_replicas = 1

    container {
      name   = "backend"
      image  = "ghcr.io/bartoszrudnik/infradockerbasics/backend:main"
      cpu    = 0.25
      memory = "0.5Gi"

      env {
        name  = "NODE_ENV"
        value = "staging"
      }
      env {
        name  = "PORT"
        value = "3000"
      }
    }
  }

  lifecycle {
    ignore_changes = [
      container_app_environment_id,
      template[0].container[0].ephemeral_storage,
      tags,
    ]
  }
}

variable "alert_email" {
  type    = string
  default = "Bartosz_Rudnik@outlook.com"
}

resource "azurerm_monitor_action_group" "main" {
  name                = "ag-infra-docker-basics"
  resource_group_name = azurerm_resource_group.main.name
  short_name          = "infradocker"

  email_receiver {
    name          = "admin"
    email_address = var.alert_email
  }
}

resource "azurerm_monitor_metric_alert" "health_check" {
  name                = "alert-health-check-failed"
  resource_group_name = azurerm_resource_group.main.name
  scopes              = [azurerm_container_app.backend.id]
  description         = "/health does not reply for 5 minutes"
  severity            = 1
  frequency           = "PT1M"
  window_size         = "PT5M"
  auto_mitigate       = true

  criteria {
    metric_namespace = "Microsoft.App/containerApps"
    metric_name      = "Requests"
    aggregation      = "Total"
    operator         = "LessThan"
    threshold        = 1

    dimension {
      name     = "statusCodeCategory"
      operator = "Include"
      values   = ["2xx"]
    }
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }
}

resource "azurerm_monitor_metric_alert" "cpu_high" {
  name                = "alert-cpu-high"
  resource_group_name = azurerm_resource_group.main.name
  scopes              = [azurerm_container_app.backend.id]
  description         = "CPU exceeded 80%"
  severity            = 2
  frequency           = "PT1M"
  window_size         = "PT5M"
  auto_mitigate       = true

  criteria {
    metric_namespace = "Microsoft.App/containerApps"
    metric_name      = "UsageNanoCores"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 200000000
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }
}

output "staging_url" {
  value = "https://${azurerm_container_app.staging.latest_revision_fqdn}/health"
}

output "backend_url" {
  value = "https://${azurerm_container_app.backend.latest_revision_fqdn}/health"
}
