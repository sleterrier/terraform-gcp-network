data "google_client_config" "current" {}

data "google_compute_network" "xpn_host" {
  count = var.xpn_host_network_name != "" ? 1 : 0

  name    = var.xpn_host_network_name
  project = var.xpn_host_project_id
}

data "google_kms_key_ring" "terraform" {
  count = local.is_kms_setup ? 1 : 0

  location = data.google_client_config.current.region
  name     = var.kms_key_ring_name
}

data "google_kms_crypto_key" "terraform" {
  count = local.is_kms_setup ? 1 : 0

  key_ring = data.google_kms_key_ring.terraform[0].self_link
  name     = var.kms_crypto_key_name
}

data "google_kms_secret" "ipsec_shared_secret" {
  for_each = {
    for label, tunnels in local.vpn_tunnels : label => tunnels
    if local.is_kms_setup
  }

  ciphertext = lookup(each.value, "shared_secret_cipher", "")
  crypto_key = data.google_kms_crypto_key.terraform[0].id
}

data "google_project" "target" {
  project_id = var.project_id
}

