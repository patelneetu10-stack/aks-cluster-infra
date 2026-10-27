variable "environment" {
  description = "Target deployment environment"
  type        = string
  default     = "prod"
}

variable "location" {
  description = "Azure region for AKS deployment"
  type        = string
  default     = "eastus"
}

variable "cluster_name" {
  description = "Base name for the AKS cluster"
  type        = string
  default     = "enterprise-aks"
}

variable "kubernetes_version" {
  description = "Kubernetes control plane version"
  type        = string
  default     = "1.29.2"
}

variable "system_node_count" {
  description = "Initial number of nodes for the System node pool"
  type        = number
  default     = 3
}

variable "system_vm_size" {
  description = "VM SKU for the System node pool"
  type        = string
  default     = "Standard_D4s_v5"
}

variable "user_node_min_count" {
  description = "Minimum auto-scaler node count for User application pool"
  type        = number
  default     = 3
}

variable "user_node_max_count" {
  description = "Maximum auto-scaler node count for User application pool"
  type        = number
  default     = 10
}

variable "user_vm_size" {
  description = "VM SKU for the User application node pool"
  type        = string
  default     = "Standard_D8s_v5"
}

variable "tags" {
  description = "Resource tags for governance and FinOps"
  type        = map(string)
  default = {
    Workload    = "Production-Kubernetes"
    Environment = "Production"
    Orchestrator= "AKS"
    ManagedBy   = "Terraform"
  }
}
