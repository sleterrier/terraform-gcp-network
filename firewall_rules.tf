/******************************************
  Locals configuration for module logic
 *****************************************/
locals {
  firewall_rules_pairs = flatten([
    for network, network_cfg in var.networks : [
      for name, rule in lookup(network_cfg, "firewall_rules", {}) : {
        name    = name
        network = network
        rule    = rule
      }
    ]
  ])

  firewall_rules = {
    for item in local.firewall_rules_pairs : "${item.network}_${item.name}" => item.rule
  }
}


/******************************************
  Create firewall rule(s)
 *****************************************/
resource "google_compute_firewall" "rule" {
  for_each = local.firewall_rules
  provider = google-beta

  description             = lookup(each.value, "description", "")
  destination_ranges      = lookup(each.value, "destination_ranges", null)
  direction               = upper(lookup(each.value, "direction", ""))
  disabled                = lookup(each.value, "disabled", false)
  enable_logging          = lookup(each.value, "enable_logging", true)
  name                    = split("_", each.key)[1]
  network                 = google_compute_network.net[split("_", each.key)[0]].name
  priority                = lookup(each.value, "priority", 1000)
  project                 = var.project_id
  source_ranges           = lookup(each.value, "source_ranges", null)
  source_service_accounts = lookup(each.value, "source_service_accounts", null)
  target_service_accounts = lookup(each.value, "target_service_accounts", null)
  source_tags             = lookup(each.value, "source_tags", null)
  target_tags             = lookup(each.value, "target_tags", null)

  dynamic "allow" {
    for_each = [
      for protocol, ports in lookup(each.value, "allow", {}) : {
        ports    = ports
        protocol = protocol
      }
    ]
    content {
      ports    = allow.value.ports
      protocol = allow.value.protocol
    }
  }

  dynamic "deny" {
    for_each = [
      for protocol, ports in lookup(each.value, "deny", {}) : {
        ports    = ports
        protocol = protocol
      }
    ]
    content {
      ports    = deny.value.ports
      protocol = deny.value.protocol
    }
  }
}

