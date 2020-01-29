/******************************************
  Locals configuration for module logic
 *****************************************/
locals {
  vpn_gateways = {
    for network_region_label, router in local.routers : network_region_label => router
    if lookup(router, "vpn_tunnels", {}) != {}
  }
}

/******************************************
  Create network VPN Gateways w/ static IPs
 *****************************************/
resource "google_compute_address" "vpngw_static_ip" {
  for_each = local.vpn_gateways

  address_type = "EXTERNAL"
  description  = "${split("_", each.key)[0]}-${split("_", each.key)[1]}-router-${split("_", each.key)[2]}-vpngw public IP"
  name         = "${split("_", each.key)[0]}-${split("_", each.key)[1]}-router-${split("_", each.key)[2]}-vpngw-addr"
  network_tier = "PREMIUM"
  project      = var.project_id
  region       = split("_", each.key)[1]
}

resource "google_compute_vpn_gateway" "vpngw" {
  for_each = local.vpn_gateways

  description = lookup(each.value, "description", null)
  name        = "${split("_", each.key)[0]}-${split("_", each.key)[1]}-router-${split("_", each.key)[2]}-vpngw"
  network     = google_compute_network.net[split("_", each.key)[0]].self_link
  project     = var.project_id
  region      = split("_", each.key)[1]
}

/******************************************
  Create forwarding rules for VPN Gateways
 *****************************************/
resource "google_compute_forwarding_rule" "vpngw_fr_esp" {
  for_each = local.vpn_gateways

  description = "Allow ESP protocol forwarding"
  ip_address  = google_compute_address.vpngw_static_ip[each.key].address
  ip_protocol = "ESP"
  name        = "${google_compute_vpn_gateway.vpngw[each.key].name}-fr-esp"
  project     = var.project_id
  region      = split("_", each.key)[1]
  target      = google_compute_vpn_gateway.vpngw[each.key].self_link
}

resource "google_compute_forwarding_rule" "vpngw_fr_udp500" {
  for_each = local.vpn_gateways

  description = "Allow UDP/500 forwarding"
  ip_address  = google_compute_address.vpngw_static_ip[each.key].address
  ip_protocol = "UDP"
  name        = "${google_compute_vpn_gateway.vpngw[each.key].name}-fr-udp500"
  port_range  = "500"
  project     = var.project_id
  region      = split("_", each.key)[1]
  target      = google_compute_vpn_gateway.vpngw[each.key].self_link
}

resource "google_compute_forwarding_rule" "vpngw_fr_udp4500" {
  for_each = local.vpn_gateways

  description = "Allow UDP/4500 forwarding"
  ip_address  = google_compute_address.vpngw_static_ip[each.key].address
  ip_protocol = "UDP"
  name        = "${google_compute_vpn_gateway.vpngw[each.key].name}-fr-udp4500"
  port_range  = "4500"
  project     = var.project_id
  region      = split("_", each.key)[1]
  target      = google_compute_vpn_gateway.vpngw[each.key].self_link
}

