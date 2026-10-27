output "aks_cluster_id" {
  description = "The ID of the AKS cluster"
  value       = azurerm_kubernetes_cluster.primary.id
}

output "aks_cluster_name" {
  description = "The name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.primary.name
}

output "aks_oidc_issuer_url" {
  description = "The OIDC issuer URL for Workload Identity integration"
  value       = azurerm_kubernetes_cluster.primary.oidc_issuer_url
}

output "acr_login_server" {
  description = "The login server for the Azure Container Registry"
  value       = azurerm_container_registry.acr.login_server
}

output "aks_kubelet_identity_object_id" {
  description = "The Object ID of the Kubelet Managed Identity"
  value       = azurerm_kubernetes_cluster.primary.kubelet_identity[0].object_id
}
