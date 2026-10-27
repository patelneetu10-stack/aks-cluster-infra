<div align="center">

# ☸️ Enterprise Azure Kubernetes Service (AKS) Infrastructure
### Production Cloud-Native Platform with Cilium eBPF, Workload Identity & Azure Key Vault CSI

[![Terraform](https://img.shields.io/badge/Terraform-%3E%3D1.5-844FBA?style=for-the-badge&logo=terraform&logoColor=white)](#)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.29-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white)](#)
[![Azure CNI Overlay](https://img.shields.io/badge/Networking-Azure_CNI_Overlay-0078D4?style=for-the-badge&logo=microsoft-azure&logoColor=white)](#)
[![Cilium eBPF](https://img.shields.io/badge/Security-Cilium_eBPF-F34B7D?style=for-the-badge&logo=cilium&logoColor=white)](#)
[![License](https://img.shields.io/badge/License-MIT-blue?style=for-the-badge)](#)

<p align="center">
  <b>Hardened, scalable, multi-tenant Kubernetes platform built on Azure with Terraform, featuring Zero-Trust Workload Identity and automated secret rotation.</b>
</p>

</div>

---

## 📌 Architecture Diagram

```mermaid
flowchart TD
    subgraph IdentityPlane ["🔑 Identity & Secrets Plane"]
        AAD["Microsoft Entra ID\n(OIDC Issuer)"]
        AKV["🔐 Azure Key Vault\n(Keys, Secrets, Certs)"]
    end

    subgraph AKSCluster ["☸️ Production AKS Cluster (10.200.0.0/16)"]
        subgraph SystemPool ["🖥️ System Node Pool (Multi-AZ 1,2,3)"]
            CoreDNS["CoreDNS / Metrics Server"]
            Cilium["Cilium eBPF Network Policies"]
        end

        subgraph UserPool ["🚀 User Workload Pool (Auto-scaling 3-10 Nodes)"]
            AppPod1["App Pod\n(Workload Identity)"]
            AppPod2["App Pod\n(Workload Identity)"]
            CSIDriver["Secrets Store CSI Driver\n(Auto-Rotation 2m)"]
        end
    end

    subgraph ContainerRegistry ["📦 Azure Container Registry (ACR)"]
        ACR["ACR Premium\n(Geo-Replication & Private Link)"]
    end

    AAD <==>|Federated Token Exchange| AppPod1
    AKV <==>|Secret Sync via CSI| CSIDriver
    CSIDriver --> AppPod1
    AKSCluster -->|AcrPull via Managed Identity| ACR
```

---

## ⚡ Key Production Capabilities

- 🔒 **Zero-Trust Workload Identity:** Microservices authenticate directly with Azure services via Microsoft Entra ID Workload Identity without hardcoded API keys or service principal secrets.
- 🚀 **Next-Gen Networking with Cilium eBPF:** High-performance Azure CNI Overlay combined with Cilium network policies delivers sub-millisecond pod-to-pod networking and L7 egress filtering.
- 🛡️ **Automated Secret Rotation:** Integrated Azure Key Vault Secrets Store CSI Driver syncs Kubernetes secrets dynamically with automatic rotation interval of 2 minutes.
- 📈 **Dynamic Elastic Auto-Scaling:** User nodepool dynamically scales from 3 to 10 nodes based on CPU/Memory thresholds and HPA (Horizontal Pod Autoscaler).
- 🧩 **Isolated System & Workload Planes:** Dedicated `systempool` tainted with `CriticalAddonsOnly` prevents application crashes from impacting core Kubernetes services.

---

## 📂 File Hierarchy

```tree
aks-cluster-infra/
├── .github/
│   └── workflows/
│       └── terraform-ci.yml      # CI pipeline for linting & Checkov security
├── .gitignore                    # Terraform and runtime ignore patterns
├── main.tf                       # AKS cluster, nodepools, ACR, and IAM bindings
├── variables.tf                  # Type-checked inputs for cluster sizing
├── outputs.tf                    # Cluster endpoints, OIDC URL, and ACR details
├── versions.tf                   # HashiCorp & Azure provider versions
├── terraform.tfvars.example      # Sample production sizing configuration
└── README.md                     # Architecture guide
```

---

## 🚀 Quick Deployment

```bash
# 1. Initialize working directory
terraform init

# 2. Validate configuration
terraform validate

# 3. Create execution plan
terraform plan -out=aks.tfplan

# 4. Deploy cluster
terraform apply aks.tfplan

# 5. Connect via kubectl
az aks get-credentials --resource-group rg-enterprise-core-prod --name aks-enterprise-core-prod
kubectl get nodes -o wide
```

---

## 📄 License
This project is open-source under the [MIT License](LICENSE).
