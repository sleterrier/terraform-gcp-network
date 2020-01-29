/******************************************
  Locals configuration for module logic
 *****************************************/
locals {
  ic_attachments_pairs = flatten([
    for network_region_label, router in local.routers : [
      for name, ic_attachment in lookup(router, "ic_attachments", {}) : {
        ic_attachment        = ic_attachment
        name                 = name
        network_region_label = network_region_label
      }
    ]
  ])

  ic_attachments = {
    for item in local.ic_attachments_pairs : "${item.network_region_label}_${item.name}" => item.ic_attachment
  }
}

/******************************************
  Create cloud-routers interconnects
 *****************************************/
resource "google_compute_interconnect_attachment" "attach" {
  for_each = local.ic_attachments

  candidate_subnets = lookup(each.value, "candidate_subnets", null)
  description       = lookup(each.value, "description", null)
  interconnect      = lookup(each.value, "interconnect_url", null)
  name              = "${split("_", each.key)[0]}-${split("_", each.key)[1]}-router-${split("_", each.key)[2]}-ic-attach-${split("_", each.key)[3]}"
  project           = var.project_id
  region            = split("_", each.key)[1]
  router            = google_compute_router.router[join("_", slice(split("_", each.key), 0, 3))].self_link
  type              = lookup(each.value, "type", "DEDICATED")
  vlan_tag8021q     = lookup(each.value, "vlan_tag8021q", null)
}

/******************************************
  Create cloud-router interfaces for
  interconnect attachments
 *****************************************/
resource "google_compute_router_interface" "ic" {
  for_each = local.ic_attachments

  interconnect_attachment = google_compute_interconnect_attachment.attach[each.key].name
  ip_range                = lookup(each.value, "router_int_ip_range", null)
  name                    = "${split("_", each.key)[0]}-${split("_", each.key)[1]}-router-${split("_", each.key)[2]}-ic-attach-${split("_", each.key)[3]}-int"
  project                 = var.project_id
  region                  = split("_", each.key)[1]
  router                  = google_compute_router.router[join("_", slice(split("_", each.key), 0, 3))].name
}

/******************************************
  Create cloud-router BGP config for
  interconnect attachments remote peers
 *****************************************/
resource "google_compute_router_peer" "ic" {
  for_each = local.ic_attachments

  advertised_route_priority = 100
  interface                 = google_compute_router_interface.ic[each.key].name
  name                      = "${split("_", each.key)[0]}-${split("_", each.key)[1]}-router-${split("_", each.key)[2]}-ic-attach-${split("_", each.key)[3]}-peer"
  peer_asn                  = lookup(each.value, "peer_asn", null)
  peer_ip_address           = lookup(each.value, "peer_ip_address", null)
  project                   = var.project_id
  region                    = split("_", each.key)[0]
  router                    = google_compute_router.router[join("_", slice(split("_", each.key), 0, 3))].name
}

