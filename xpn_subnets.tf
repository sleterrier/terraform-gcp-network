/******************************************
  Make target project an XPN service project
 *****************************************/
resource "google_compute_shared_vpc_service_project" "xpn_service" {
  count           = local.is_xpn_service ? 1 : 0
  host_project    = var.xpn_host_project_id
  service_project = var.project_id
}

/******************************************
  Create subnetwork(s) in XPN host project
 *****************************************/
resource "google_compute_subnetwork" "xpn_subnet" {
  for_each = var.xpn_subnets
  provider = google-beta

  description = <<-EOF
    XPN host :: ${var.xpn_host_project_id}
    Team     :: ${var.xpn_subnets_label}
    Project  :: ${data.google_project.target.id}
    Subnet   :: ${each.key}
    Region   :: ${lookup(each.value, "region")}
  EOF

  enable_flow_logs         = lookup(each.value, "enable_flow_logs", true)
  ip_cidr_range            = lookup(each.value, "ip_cidr_range")
  name                     = "${var.xpn_subnets_label}-${data.google_project.target.name}-${each.key}"
  network                  = data.google_compute_network.xpn_host[0].self_link
  private_ip_google_access = lookup(each.value, "private_ip_google_access", true)
  project                  = var.xpn_host_project_id
  region                   = lookup(each.value, "region")

  dynamic "log_config" {
    for_each = [
      for key, values in lookup(each.value, "log_config", {}) : {
        aggregation_interval = lookup(values, "aggregation_interval", null)
        flow_sampling        = lookup(values, "flow_sampling", null)
        metadata             = lookup(values, "metadata", null)
      }
    ]
    content {
      aggregation_interval = lookup(log_config.value, "aggregation_interval", null)
      flow_sampling        = lookup(log_config.value, "flow_sampling", null)
      metadata             = lookup(log_config.value, "metadata", null)
    }
  }

  dynamic "secondary_ip_range" {
    for_each = [
      for name, range in lookup(each.value, "secondary_ip_ranges", {}) : {
        ip_cidr_range = range
        range_name    = name
      }
    ]
    content {
      ip_cidr_range = secondary_ip_range.value.ip_cidr_range
      range_name    = secondary_ip_range.value.range_name
    }
  }
}

/******************************************
  Grant networkUser role on XPN subnet(s)
 *****************************************/
resource "google_compute_subnetwork_iam_binding" "xpn_subnet" {
  provider = google-beta
  for_each = var.xpn_subnets

  members    = var.xpn_networkUser_members
  project    = var.xpn_host_project_id
  region     = each.value["region"]
  role       = "roles/compute.networkUser"
  subnetwork = google_compute_subnetwork.xpn_subnet[each.key].name
}

/******************************************
  Create default INGRESS firewall rule
  Allow all traffic from subnet itself
  NOTE: maybe later! Least privileges approach for now
 *****************************************/
#resource "google_compute_firewall" "ingress-default-self-rule" {
#  for_each = var.xpn_subnets
#  provider = google-beta
#
#  description    = "SELFSERVICE|INGRESS - ALLOW all traffic from ANY clients in ${data.google_project.target.name}-${each.key} subnet"
#  direction      = "INGRESS"
#  enable_logging = false
#  name           = "ingress-allow-tag-from-cidr-${var.xpn_subnets_label}-${data.google_project.target.name}-${each.key}"
#  network        = var.xpn_host_network_name
#  priority       = 10000
#  project        = var.xpn_host_project_id
#  source_ranges  = [ each.value["ip_cidr_range"] ]
#  target_tags    = [ "allow-from-${var.xpn_subnets_label}-${data.google_project.target.name}-${each.key}",
#                     "${var.xpn_subnets_label}" ]
#
#  allow {
#    ports    = []
#    protocol = "icmp"
#  }
#
#  allow {
#    ports    = []
#    protocol = "tcp"
#  }
#
#  allow {
#    ports    = []
#    protocol = "udp"
#  }
#}

