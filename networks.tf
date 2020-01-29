/******************************************
  Create VPC network(s)
 *****************************************/
resource "google_compute_network" "net" {
  for_each = var.networks

  auto_create_subnetworks         = false
  delete_default_routes_on_create = lookup(each.value, "delete_default_routes_on_create", false)
  description                     = lookup(each.value, "description", null)
  name                            = each.key
  project                         = var.project_id
  routing_mode                    = lookup(each.value, "routing_mode", "GLOBAL")
}

/******************************************
  Create VPC default network
 *****************************************/
resource "google_compute_network" "auto_net" {
  count = var.is_auto_network ? 1 : 0

  auto_create_subnetworks         = false
  delete_default_routes_on_create = false
  description                     = "Default network with flow-logging enabled"
  name                            = "default"
  project                         = var.project_id
  routing_mode                    = "REGIONAL"
}

/******************************************
  Shared VPC
 *****************************************/
resource "google_compute_shared_vpc_host_project" "xpn_host" {
  count   = var.is_xpn_host ? 1 : 0
  project = var.project_id

  depends_on = [google_compute_network.net]
}

