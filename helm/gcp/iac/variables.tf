variable "project_id" {
  description = "GCP project ID"
  type        = string
}


variable "k8s_namespace" {
  description = "Kubernetes namespace of the workload"
  type        = string
  default     = "dev"
}

variable "k8s_sa_name" {
  description = "Kubernetes service account name"
  type        = string
  default     = "products"
}
