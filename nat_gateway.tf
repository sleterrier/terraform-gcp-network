/******************************************
  Locals configuration for module logic
 *****************************************/
locals {
  nat_gateways = {
    for network_region_label, router in local.routers : network_region_label => router["nat_gateway"]
    if lookup(router, "nat_gateway", "UNDEFINED") != "UNDEFINED"
  }
}

/******************************************
  Create cloud-routers NAT gateways
  with static external IPs
 *****************************************/
resource "google_compute_address" "nat_gateway_address_1" {
  for_each = local.nat_gateways

  address_type = "EXTERNAL"
  description  = "${split("_", each.key)[0]}-${split("_", each.key)[1]}-router-${split("_", each.key)[2]}-natgw public IP #1"
  name         = "${split("_", each.key)[0]}-${split("_", each.key)[1]}-router-${split("_", each.key)[2]}-natgw-addr-1"
  network_tier = "PREMIUM"
  project      = var.project_id
  region       = split("_", each.key)[1]
}

resource "google_compute_address" "nat_gateway_address_2" {
  for_each = local.nat_gateways

  address_type = "EXTERNAL"
  description  = "${split("_", each.key)[0]}-${split("_", each.key)[1]}-router-${split("_", each.key)[2]}-natgw public IP #2"
  name         = "${split("_", each.key)[0]}-${split("_", each.key)[1]}-router-${split("_", each.key)[2]}-natgw-addr-2"
  network_tier = "PREMIUM"
  project      = var.project_id
  region       = split("_", each.key)[1]
}

resource "google_compute_router_nat" "gateway" {
  for_each = local.nat_gateways

  icmp_idle_timeout_sec              = lookup(each.value, "icmp_idle_timeout_sec", 30)
  name                               = "${split("_", each.key)[0]}-${split("_", each.key)[1]}-router-${split("_", each.key)[2]}-natgw"
  project                            = var.project_id
  region                             = split("_", each.key)[1]
  router                             = google_compute_router.router[each.key].name
  nat_ip_allocate_option             = "MANUAL_ONLY"
  nat_ips                            = [google_compute_address.nat_gateway_address_1[each.key].self_link, google_compute_address.nat_gateway_address_2[each.key].self_link]
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  tcp_established_idle_timeout_sec   = lookup(each.value, "tcp_established_idle_timeout_sec", 1200)
  tcp_transitory_idle_timeout_sec    = lookup(each.value, "tcp_transitory_idle_timeout_sec", 30)
  udp_idle_timeout_sec               = lookup(each.value, "udp_idle_timeout_sec", 30)

  log_config {
    filter = lookup(each.value, "log_filter", "ALL")
    enable = lookup(each.value, "log_enable", true)
  }
}

