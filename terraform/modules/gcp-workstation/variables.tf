variable "project_id" {
  description = "GCP project ID where the workstation resources are created."
  type        = string
}

variable "zone" {
  description = "GCP zone for the workstation VM."
  type        = string
}

variable "workstation_name" {
  description = "Name of the workstation VM."
  type        = string
}

variable "machine_type" {
  description = "Compute Engine machine type for the workstation VM."
  type        = string
}

variable "disk_size_gb" {
  description = "Boot disk size in GB."
  type        = number
}

variable "home_disk_size_gb" {
  description = "Persistent home disk size in GB."
  type        = number
}

variable "forge_user" {
  description = "Bootstrap admin user created on the workstation."
  type        = string
  default     = "forge"
}

variable "network_self_link" {
  description = "Self link for the shared workstation VPC network."
  type        = string
}

variable "subnetwork_self_link" {
  description = "Self link for the shared workstation subnetwork."
  type        = string
}

variable "network_tags" {
  description = "Network tags applied to the workstation VM."
  type        = list(string)
  default     = []
}

variable "tailscale_hostname" {
  description = "Tailscale node hostname. Empty value falls back to workstation_name."
  type        = string
  default     = ""
}

variable "tailscale_tags" {
  description = "Tailscale tags advertised by the workstation."
  type        = list(string)
  default     = []
}

variable "tailscale_secret_name" {
  description = "Secret Manager secret name storing the Tailscale auth key."
  type        = string
}

variable "enable_tailscale_ssh" {
  description = "Whether to pass --ssh to tailscale up."
  type        = bool
  default     = true
}
