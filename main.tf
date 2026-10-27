# ==============================================================================
# Enterprise Azure Kubernetes Service (AKS) Production Infrastructure
# ==============================================================================

# 1. Resource Group
resource "azurerm_resource_group" "aks" {
  name     = "rg-${var.cluster_name}-${var.environment}"
  location = var.location
  tags     = var.tags
}

# 2. Virtual Network & Dedicated AKS Subnet
resource "azurerm_virtual_network" "aks" {
  name                = "vnet-aks-${var.environment}"
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name
  address_space       = ["10.200.0.0/16"]
  tags                = var.tags
}

resource "azurerm_subnet" "nodes" {
  name                 = "snet-aks-nodes"
  resource_group_name  = azurerm_resource_group.aks.name
  virtual_network_name = azurerm_virtual_network.aks.name
  address_prefixes     = ["10.200.0.0/20"]
}

# 3. Azure Container Registry (ACR)
resource "azurerm_container_registry" "acr" {
  name                = replace("acr${var.cluster_name}${var.environment}", "-", "")
  resource_group_name = azurerm_resource_group.aks.name
  location            = azurerm_resource_group.aks.location
  sku                 = "Premium"
  admin_enabled       = false
  tags                = var.tags
}

# 4. Managed Identities
resource "azurerm_user_assigned_identity" "aks_control_plane" {
  name                = "id-aks-${var.cluster_name}-${var.environment}"
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name
  tags                = var.tags
}

# 5. Log Analytics Workspace for Container Insights
resource "azurerm_log_analytics_workspace" "aks" {
  name                = "law-aks-${var.cluster_name}-${var.environment}"
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name
  sku                 = "PerGB2018"
  retention_in_days   = 60
  tags                = var.tags
}

# 6. Production AKS Cluster
resource "azurerm_kubernetes_cluster" "primary" {
  name                = "aks-${var.cluster_name}-${var.environment}"
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name
  dns_prefix          = "aks-${var.cluster_name}-${var.environment}"
  kubernetes_version  = var.kubernetes_version
  sku_tier            = "Standard"
  tags                = var.tags

  # Workload Identity & OIDC Issuer for Zero-Trust pods
  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  default_node_pool {
    name                = "systempool"
    node_count          = var.system_node_count
    vm_size             = var.system_vm_size
    vnet_subnet_id      = azurerm_subnet.nodes.id
    zones               = ["1", "2", "3"]
    os_disk_size_gb     = 128
    os_disk_type        = "Managed"
    enable_auto_scaling = false
    only_critical_addons_enabled = true

    upgrade_settings {
      max_surge = "33%"
    }
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aks_control_plane.id]
  }

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    network_policy      = "cilium"
    ebpf_data_plane     = "cilium"
    load_balancer_sku   = "standard"
  }

  # Azure Key Vault Secrets Store CSI Driver integration
  key_vault_secrets_provider {
    secret_rotation_enabled  = true
    secret_rotation_interval = "2m"
  }

  # Container Insights telemetry
  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.aks.id
  }

  lifecycle {
    ignore_changes = [
      default_node_pool[0].node_count
    ]
  }
}

# 7. User Node Pool for Application Workloads (Auto-scaling VMSS)
resource "azurerm_kubernetes_cluster_node_pool" "user" {
  name                  = "userpool"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.primary.id
  vm_size               = var.user_vm_size
  vnet_subnet_id        = azurerm_subnet.nodes.id
  zones                 = ["1", "2", "3"]
  enable_auto_scaling   = true
  min_count             = var.user_node_min_count
  max_count             = var.user_node_max_count
  os_disk_size_gb       = 256
  os_type               = "Linux"
  mode                  = "User"
  tags                  = var.tags

  upgrade_settings {
    max_surge = "25%"
  }
}

# 8. Role Assignment: AKS Pull from ACR
resource "azurerm_role_assignment" "aks_acr_pull" {
  principal_id                     = azurerm_kubernetes_cluster.primary.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.acr.id
  skip_service_principal_aad_check = true
}
