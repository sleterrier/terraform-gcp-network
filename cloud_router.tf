/******************************************
  Locals configuration for module logic
  Create label_routers maps per region
 *****************************************/
locals {
  routers_pairs = flatten([
    for network, network_cfg in var.networks : [
      for region, labels in lookup(network_cfg, "cloud_routers", {}) : [
        for label, routers in labels : {
          label   = label
          network = network
          region  = region
          routers = routers
        }
      ]
    ]
  ])

  routers = {
    for item in local.routers_pairs : "${item.network}_${item.region}_${item.label}" => item.routers
  }
}

/******************************************
  Create cloud-routers and apply BGP
  config if specified
 *****************************************/
resource "google_compute_router" "router" {
  for_each = local.routers

  description = lookup(each.value, "description", null)
  name        = "${split("_", each.key)[0]}-${split("_", each.key)[1]}-router-${split("_", each.key)[2]}"
  network     = google_compute_network.net[split("_", each.key)[0]].self_link
  project     = var.project_id
  region      = split("_", each.key)[1]

  dynamic "bgp" {
    for_each = {
      for key, value in each.value : key => value
      if key == "bgp"
    }

    content {
      advertise_mode    = lookup(bgp.value, "advertise_mode", "DEFAULT")
      advertised_groups = lookup(bgp.value, "advertised_groups", null)
      asn               = lookup(bgp.value, "asn", null)

      dynamic "advertised_ip_ranges" {
        for_each = [for range in lookup(bgp.value, "advertised_ip_ranges", []) : {
          range = range
        }]

        content {
          range = advertised_ip_ranges.value.range
        }
      }
    }
  }
}

