/******************************************
  Locals configuration for module logic
 *****************************************/
locals {
  vpn_tunnels_pairs = flatten([
    for network_region_label, gateway in local.vpn_gateways : [
      for name, vpn_tunnel in gateway["vpn_tunnels"] : {
        name                 = name
        network_region_label = network_region_label
        vpn_tunnel           = vpn_tunnel
      }
      if lookup(gateway, "vpn_tunnels", {}) != {}
    ]
  ])

  vpn_tunnels = {
    for item in local.vpn_tunnels_pairs : "${item.network_region_label}_${item.name}" => item.vpn_tunnel
  }
}

/******************************************
  Create cloud-router VPN tunnels
 *****************************************/
resource "google_compute_vpn_tunnel" "tunnel" {
  for_each = local.vpn_tunnels

  description        = lookup(each.value, "description", null)
  ike_version        = lookup(each.value, "ike_version", 2)
  name               = "${split("_", each.key)[0]}-${split("_", each.key)[1]}-router-${split("_", each.key)[2]}-vpn-${split("_", each.key)[3]}-tun"
  peer_ip            = lookup(each.value, "peer_ip", null)
  project            = var.project_id
  region             = split("_", each.key)[1]
  router             = google_compute_router.router[join("_", slice(split("_", each.key), 0, 3))].self_link
  shared_secret      = data.google_kms_secret.ipsec_shared_secret[each.key].plaintext
  target_vpn_gateway = google_compute_vpn_gateway.vpngw[join("_", slice(split("_", each.key), 0, 3))].self_link

  depends_on = [
    google_compute_forwarding_rule.vpngw_fr_esp,
    google_compute_forwarding_rule.vpngw_fr_udp500,
    google_compute_forwarding_rule.vpngw_fr_udp4500,
  ]
}

/******************************************
  Create cloud-router interfaces for
  VPN tunnels
 *****************************************/
resource "google_compute_router_interface" "vpn" {
  for_each = local.vpn_tunnels

  ip_range   = lookup(each.value, "router_int_ip_range", "")
  name       = "${split("_", each.key)[0]}-${split("_", each.key)[1]}-router-${split("_", each.key)[2]}-vpn-${split("_", each.key)[3]}-int"
  project    = var.project_id
  region     = split("_", each.key)[1]
  router     = google_compute_router.router[join("_", slice(split("_", each.key), 0, 3))].name
  vpn_tunnel = google_compute_vpn_tunnel.tunnel[each.key].name
}

/******************************************
  Create cloud-router BGP config for
  VPN Tunnels remote peers
 *****************************************/
resource "google_compute_router_peer" "vpn" {
  for_each = local.vpn_tunnels

  advertised_route_priority = lookup(each.value, "advertised_route_priority", null)
  interface                 = google_compute_router_interface.vpn[each.key].name
  name                      = "${split("_", each.key)[0]}-${split("_", each.key)[1]}-router-${split("_", each.key)[2]}-vpn-${split("_", each.key)[3]}-peer"
  peer_asn                  = lookup(each.value, "peer_asn", null)
  peer_ip_address           = lookup(each.value, "router_int_peer_ip", null)
  project                   = var.project_id
  region                    = split("_", each.key)[1]
  router                    = google_compute_router.router[join("_", slice(split("_", each.key), 0, 3))].name
}

