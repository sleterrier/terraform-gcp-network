/******************************************
  Locals configuration for module logic
 *****************************************/
locals {
  subnets_pairs = flatten([
    for network, network_cfg in var.networks : [
      for name, subnet in lookup(network_cfg, "subnets", {}) : {
        name    = name
        network = network
        subnet  = subnet
      }
    ]
  ])

  subnets = {
    for item in local.subnets_pairs : "${item.network}_${item.name}" => item.subnet
  }
}

/******************************************
  Create subnet(s)
 *****************************************/
resource "google_compute_subnetwork" "subnet" {
  provider = google-beta
  for_each = local.subnets

  description              = lookup(each.value, "description", null)
  enable_flow_logs         = lookup(each.value, "enable_flow_logs", false)
  ip_cidr_range            = lookup(each.value, "ip_cidr_range")
  name                     = split("_", each.key)[1]
  network                  = google_compute_network.net[split("_", each.key)[0]].self_link
  private_ip_google_access = lookup(each.value, "private_ip_google_access", false)
  project                  = var.project_id
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
  Create auto subnets with flow logging
 *****************************************/
resource "google_compute_subnetwork" "auto_subnet" {
  provider = google-beta
  for_each = {
    for region, cidr in {
      "asia-east1"              = "10.140.0.0/20"
      "asia-east2"              = "10.170.0.0/20"
      "asia-northeast1"         = "10.146.0.0/20"
      "asia-northeast2"         = "10.174.0.0/20"
      "asia-south1"             = "10.160.0.0/20"
      "asia-southeast1"         = "10.148.0.0/20"
      "australia-southeast1"    = "10.152.0.0/20"
      "europe-north1"           = "10.166.0.0/20"
      "europe-west1"            = "10.132.0.0/20"
      "europe-west2"            = "10.154.0.0/20"
      "europe-west3"            = "10.156.0.0/20"
      "europe-west4"            = "10.164.0.0/20"
      "europe-west6"            = "10.172.0.0/20"
      "northamerica-northeast1" = "10.162.0.0/20"
      "southamerica-east1"      = "10.158.0.0/20"
      "us-central1"             = "10.128.0.0/20"
      "us-east1"                = "10.142.0.0/20"
      "us-east4"                = "10.150.0.0/20"
      "us-west1"                = "10.138.0.0/20"
      "us-west2"                = "10.168.0.0/20"
    } : region => cidr if var.is_auto_network
  }

  enable_flow_logs         = true
  ip_cidr_range            = each.value
  name                     = "default"
  network                  = google_compute_network.auto_net[0].self_link
  private_ip_google_access = false
  project                  = var.project_id
  region                   = each.key

  log_config {
    aggregation_interval = "INTERVAL_10_MIN"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

