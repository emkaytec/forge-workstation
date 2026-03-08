locals {
  default_network_tag          = "${var.workstation_name}-workstation"
  network_tags                 = distinct(concat(var.network_tags, [local.default_network_tag]))
  tailscale_hostname_effective = trimspace(var.tailscale_hostname) != "" ? trimspace(var.tailscale_hostname) : var.workstation_name
  tailscale_tags_csv           = join(",", var.tailscale_tags)
  service_account_id           = "ws-${substr(md5(var.workstation_name), 0, 24)}"
  home_disk_device_path        = "/dev/disk/by-id/google-${var.workstation_name}-home"
  home_mount_path              = "/home/${var.forge_user}"
}

resource "google_service_account" "workstation" {
  project      = var.project_id
  account_id   = local.service_account_id
  display_name = "Workstation service account for ${var.workstation_name}"
}

resource "google_secret_manager_secret_iam_member" "workstation_tailscale_authkey_accessor" {
  project   = var.project_id
  secret_id = var.tailscale_secret_name
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.workstation.email}"
}

resource "google_compute_disk" "workstation_home" {
  project = var.project_id
  zone    = var.zone
  name    = "${var.workstation_name}-home"
  type    = "pd-balanced"
  size    = var.home_disk_size_gb
}

resource "google_compute_instance" "workstation" {
  project                   = var.project_id
  zone                      = var.zone
  name                      = var.workstation_name
  machine_type              = var.machine_type
  tags                      = local.network_tags
  allow_stopping_for_update = true

  depends_on = [
    google_secret_manager_secret_iam_member.workstation_tailscale_authkey_accessor,
  ]

  boot_disk {
    initialize_params {
      image = "projects/ubuntu-os-cloud/global/images/family/ubuntu-2404-lts-amd64"
      size  = var.disk_size_gb
      type  = "pd-balanced"
    }
  }

  network_interface {
    network    = var.network_self_link
    subnetwork = var.subnetwork_self_link
  }

  attached_disk {
    source      = google_compute_disk.workstation_home.id
    device_name = google_compute_disk.workstation_home.name
    mode        = "READ_WRITE"
  }

  service_account {
    email  = google_service_account.workstation.email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  metadata_startup_script = templatefile("${path.module}/templates/startup.sh.tftpl", {
    project_id            = var.project_id
    tailscale_secret_name = var.tailscale_secret_name
    tailscale_hostname    = local.tailscale_hostname_effective
    tailscale_tags_csv    = local.tailscale_tags_csv
    enable_tailscale_ssh  = var.enable_tailscale_ssh
    forge_user            = var.forge_user
    home_disk_device_path = local.home_disk_device_path
    home_mount_path       = local.home_mount_path
  })

  metadata = {
    "block-project-ssh-keys" = "true"
  }
}
