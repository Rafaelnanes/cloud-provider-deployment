terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
}

resource "google_service_account" "products_sa" {
  account_id   = "products-sa"
  display_name = "Products Service Account"
}

resource "google_project_iam_member" "products_sa_secretmanager" {
  depends_on = [google_service_account.products_sa]
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.products_sa.email}"
}

resource "google_service_account_iam_member" "products_workload_identity" {
  service_account_id = google_service_account.products_sa.name
  depends_on         = [google_service_account.products_sa]
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[${var.k8s_namespace}/${var.k8s_sa_name}]"
}

output "products_sa_email" {
  value = google_service_account.products_sa.email
}
