resource "google_compute_firewall" "xpn_rule" {
  for_each = var.xpn_firewall_rules
  provider = google-beta

  description             = lookup(each.value, "description", "")
  destination_ranges      = lookup(each.value, "destination_ranges", null)
  direction               = upper(lookup(each.value, "direction", ""))
  disabled                = lookup(each.value, "disabled", false)
  enable_logging          = lookup(each.value, "enable_logging", true)
  name                    = each.key
  network                 = var.xpn_host_network_name
  priority                = lookup(each.value, "priority", 1000)
  project                 = var.xpn_host_project_id
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

