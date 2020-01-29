/******************************************
  Locals configuration for module logic
 *****************************************/
locals {
  routes_pairs = flatten([
    for network, network_cfg in var.networks : [
      for name, route in lookup(network_cfg, "routes", {}) : {
        name    = name
        network = network
        route   = route
      }
    ]
  ])

  routes = {
    for item in local.routes_pairs : "${item.network}_${item.name}" => item.route
  }
}


/******************************************
  Create routes
 *****************************************/
resource "google_compute_route" "route" {
  for_each = local.routes

  project                = var.project_id
  network                = google_compute_network.net[split("_", each.key)[0]].name
  name                   = split("_", each.key)[1]
  description            = lookup(each.value, "description", null)
  tags                   = lookup(each.value, "tags", null)
  dest_range             = lookup(each.value, "dest_range")
  next_hop_gateway       = lookup(each.value, "next_hop_gateway", null)
  next_hop_ip            = lookup(each.value, "next_hop_ip", null)
  next_hop_instance      = lookup(each.value, "next_hop_instance", null)
  next_hop_instance_zone = lookup(each.value, "next_hop_instance_zone", null)
  next_hop_vpn_tunnel    = lookup(each.value, "next_hop_vpn_tunnel", null)
  priority               = lookup(each.value, "priority", 1000)
}

