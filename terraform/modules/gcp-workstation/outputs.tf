output "instance_name" {
  description = "Workstation VM name."
  value       = google_compute_instance.workstation.name
}

output "instance_id" {
  description = "Workstation VM numeric instance ID."
  value       = google_compute_instance.workstation.instance_id
}

output "instance_self_link" {
  description = "Workstation VM self link."
  value       = google_compute_instance.workstation.self_link
}

output "internal_ip" {
  description = "Workstation internal IP address."
  value       = google_compute_instance.workstation.network_interface[0].network_ip
}

output "tailscale_hostname" {
  description = "Expected Tailscale hostname for SSH."
  value       = local.tailscale_hostname_effective
}

output "home_disk_name" {
  description = "Persistent disk name mounted as the forge home directory."
  value       = google_compute_disk.workstation_home.name
}
