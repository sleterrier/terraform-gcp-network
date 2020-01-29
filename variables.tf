variable "is_auto_network" {
  description = "When set to true, automatically create default network with a /20 subnet (w/ flow logging enabled) for each GCP region across the 10.128.0.0/9 address range"
  default     = false
  type        = bool
}

variable "is_xpn_host" {
  description = "Makes this project a Shared VPC host if true (default false)"
  default     = false
  type        = bool
}

variable "kms_crypto_key_name" {
  default     = ""
  description = "KMS CryptoKey name"
  type        = string
}

variable "kms_key_ring_name" {
  default     = ""
  description = "KMS KeyRing name"
  type        = string
}

variable "networks" {
  default     = {}
  description = "Map of maps defining VPC networks and their associated resources per region"
  type        = any
}

variable "project_id" {
  description = "Target Project (id)"
  type        = string
}

variable "xpn_firewall_rules" {
  default     = {}
  description = "Map of maps defining firewall rules to create in Shared VPC host network"
  type        = any
}

variable "xpn_host_network_name" {
  default     = ""
  description = "Shared VPC host network name"
  type        = string
}

variable "xpn_host_project_id" {
  default     = ""
  description = "Shared VPC host project ID"
  type        = string
}

variable "xpn_networkUser_members" {
  default     = []
  description = "List of user(s), group(s) and service account(s) to grant NetworkUser role on xpn_subnets"
  type        = list(string)
}

variable "xpn_subnets" {
  default     = {}
  description = "Map of maps defining subnetworks to create in Shared VPC host network"
  type        = any
}

variable "xpn_subnets_label" {
  default     = "subnet"
  description = "Label to associate with subnets created in Shared VPC host network"
  type        = string
}

