output "cloud_routers" {
  description = "Map of cloud-routers maps per network"
  value       = google_compute_router.router
}

output "firewall_rules" {
  description = "Map of Firewall rules maps per network"
  value       = google_compute_firewall.rule
}

output "interconnect_attachments" {
  description = "Map of IC attachments maps per network/cloud-router"
  value       = google_compute_interconnect_attachment.attach
}

output "interconnect_attachments_routers_interfaces" {
  description = "Map of IC attachements routers interfaces maps per network/cloud-router"
  value       = google_compute_router_interface.ic
}

output "interconnect_attachments_routers_interfaces_peers" {
  description = "Map of IC attachments routers interfaces peers maps per network/cloud-router"
  value       = google_compute_router_peer.ic
}

output "nat_gateways" {
  description = "Map of nat-gateways maps per network"
  value       = google_compute_router_nat.gateway
}

output "networks" {
  description = "Map of networks maps"
  value       = google_compute_network.net
}

output "routes" {
  description = "Map of routes maps per network"
  value       = google_compute_route.route
}

output "subnets" {
  description = "Map of subnets maps per network"
  value       = google_compute_subnetwork.subnet
}

output "vpn_gateways" {
  description = "Map of vpn-gateways maps per network/cloud-router"
  value       = google_compute_vpn_gateway.vpngw
}

output "vpn_tunnels" {
  description = "Map of vpn-tunnels maps per network/cloud-router"
  value       = google_compute_vpn_tunnel.tunnel
}

output "vpn_tunnels_routers_interfaces" {
  description = "Map of vpn-tunnels routers interfaces maps per network/cloud-router"
  value       = google_compute_router_interface.vpn
}

output "vpn_tunnels_routers_interfaces_peers" {
  description = "Map of vpn-tunnels routers interfaces peers maps per network/cloud-router"
  value       = google_compute_router_peer.vpn
}

output "xpn_firewall_rules" {
  description = "Map of firewall rules maps on XPN host network"
  value       = google_compute_firewall.xpn_rule
}

output "xpn_subnets" {
  description = "Map of subnets maps on XPN host network"
  value       = google_compute_subnetwork.xpn_subnet
}

