# terraform-gcp-network

This modules makes it easier to set up VPC Networks in GCP by defining your network(s) and its associated resource(s) from a single input map.

It supports creating/managing:

- Google Virtual Private Networks (VPCs)
  - Shared VPC host project
  - Subnets within each network
    - Secondary ranges within each subnet
  - Firewall rules within each network
  - Static routes with each network
  - Standalone/HA (per region) Cloud Routers within each network
    - Interconnect Attachment(s) for each Cloud Router
    - NAT Gateway (per region)
      - WARNING: only one NAT Gateway can be created per region. See examples.
    - VPN Gateway for each Cloud Router
    - VPN Tunnel(s) for each Cloud Router
      - KMS encryption for shared_secret

- Shared VPC service project
  - Subnets within a given Shared VPC Network
  - NetworkUsers permissions for each XPN subnet

## Usage
**NOTE: Click on the ">" to expand each example**

<details><summary>1x Network, 2x Subnets</summary>
<p>

```hcl
module "network" {
  source  = "../modules/gcp-network"

  project_id = "<project_id>"
  networks   = {
      "network-name" = {
          auto_create_subnetworks = false
          description             = "Example network"
          routing_mode            = "REGIONAL"

          subnets = {
              "subnet-name-1" = {
                  ip_cidr_range            = "10.100.1.0/24"
                  enable_flow_logs         = true
                  private_ip_google_access = true
                  region                   = "us-west2"
              }

              "subnet-name-2" = {
                  ip_cidr_range            = "10.120.1.0/24"
                  enable_flow_logs         = true
                  private_ip_google_access = true
                  region                   = "asia-southeast1"
              }
          } ## END subnets
      } ## END network-name
  } ## END networks
}
```
</p>
</details>

<details><summary>2x Networks with static routes and custom FW rules, 2x Subnets per network</summary>
<p>

```hcl
module "network" {
  source  = "../modules/gcp-network"

  project_id = "<project_id>"
  networks   = {
      "network-name-1" = {
          auto_create_subnetworks         = false
          delete_default_routes_on_create = true
          description                     = "Example network"
          routing_mode                    = "REGIONAL"

          subnets = {
              "subnet-name-1" = {
                  ip_cidr_range            = "10.100.1.0/24"
                  enable_flow_logs         = true
                  private_ip_google_access = true
                  region                   = "us-west2"
              }

              "subnet-name-2" = {
                  ip_cidr_range            = "10.120.1.0/24"
                  enable_flow_logs         = true
                  private_ip_google_access = true
                  region                   = "asia-southeast1"
              }
          } ## END subnets

          routes = {
              "egress-internet" = {
                  description       = "Static route through IGW to access internet"
                  dest_range        = "0.0.0.0/0"
                  next_hop_gateway  = "default-internet-gateway"
                  priority          = 10000
                  tags              = [ "egress-internet" ]
              }

              "app-proxy" = {
                  description            = "Static route through proxy to reach app"
                  dest_range             = "10.100.10.0/24"
                  next_hop_instance      = "app-proxy-instance"
                  next_hop_instance_zone = "us-west2-a"
                  tags                   = [ "egress-app-proxy" ]
              }
          } ## END routes

          firewall_rules = {
              "ingress-allow-tag-lb-health-checks" = {
                  description   = "SELFSERVICE|INGRESS - ALLOW health checks from HTTP(S), SSL/TCP Proxy and Internal HTTP(s)/TCP/UDP Load Balancers"
                  direction     = "INGRESS"
                  priority      = 10

                  allow = {
                      "tcp"     = []
                  }

                  source_ranges = [ "35.191.0.0/16",
                                    "130.211.0.0/22", ]

                  target_tags   = [ "allow-health-checks-from-lb" ]
              }


              "ingress-allow-tag-network-lb-health-checks" = {
                  description   = "SELFSERVICE|INGRESS - ALLOW legacy health checks from Network Load Balancers"
                  direction     = "INGRESS"
                  priority      = 10

                  allow = {
                      "tcp"     = []
                  }

                  source_ranges = [ "35.191.0.0/16",
                                    "209.85.152.0/22",
                                    "209.85.204.0/22", ]

                  target_tags   = [ "allow-health-checks-from-network-lb" ]
              }
          } ## END firewall_rules
      } ## END network-name-1

      "network-name-2" = {
          auto_create_subnetworks = false
          description             = "Example network"
          routing_mode            = "REGIONAL"

          firewall_rules = {
              "ingress-allow-tag-lb-health-checks" = {
                  description   = "SELFSERVICE|INGRESS - ALLOW health checks from HTTP(S), SSL/TCP Proxy and Internal HTTP(s)/TCP/UDP Load Balancers"
                  direction     = "INGRESS"
                  priority      = 10

                  allow = {
                      "tcp"     = []
                  }

                  source_ranges = [ "35.191.0.0/16",
                                    "130.211.0.0/22", ]

                  target_tags   = [ "allow-health-checks-from-lb" ]
              }


              "ingress-allow-tag-network-lb-health-checks" = {
                  description   = "SELFSERVICE|INGRESS - ALLOW legacy health checks from Network Load Balancers"
                  direction     = "INGRESS"
                  priority      = 10

                  allow = {
                      "tcp"     = []
                  }

                  source_ranges = [ "35.191.0.0/16",
                                    "209.85.152.0/22",
                                    "209.85.204.0/22", ]

                  target_tags   = [ "allow-health-checks-from-network-lb" ]
              }
          } ## END firewall_rules

          routes = {
              "egress-internet" = {
                  description       = "Static route through IGW to access internet"
                  dest_range        = "0.0.0.0/0"
                  next_hop_gateway  = "default-internet-gateway"
                  priority          = 10000
                  tags              = [ "egress-internet" ]
              }

              "app-proxy" = {
                  description            = "Static route through proxy to reach app"
                  dest_range             = "10.200.10.0/24"
                  next_hop_instance      = "app-proxy-instance"
                  next_hop_instance_zone = "us-west2-b"
                  tags                   = [ "egress-app-proxy" ]
              }
          } ## END routes

          subnets = {
              "subnet-name-1" = {
                  ip_cidr_range            = "10.110.1.0/24"
                  enable_flow_logs         = true
                  private_ip_google_access = true
                  region                   = "europe-west4"
              }

              "subnet-name-2" = {
                  ip_cidr_range            = "10.130.1.0/24"
                  enable_flow_logs         = true
                  private_ip_google_access = true
                  region                   = "southamerica-east1"
              }
          } ## END subnets
      } ## END network-name-2
  } ## END networks
}
```
</p>
</details>

<details><summary>1x Network, 4x Cloud-Routers in 2x Regions, 2x NAT-Gateways</summary>
<p>

```hcl
module "network" {
  source  = "../modules/gcp-network"

  project_id = "<project_id>"
  networks   = {
      "network-name" = {
          auto_create_subnetworks = false
          description             = "Example network"
          routing_mode            = "REGIONAL"

          cloud_routers = {
              "us-west2" = {
                   "primary" = {
                       "nat_gateway" = {}
                   }

                   "secondary" = {}
              } ## END us-west2

              "eu-west4" = {
                   "primary" = {
                       "nat_gateway" = {}
                   } ## END primary

                   "secondary" = {}
              } ## END eu-west4
          } ## END cloud_routers
      } ## END network-name
  } ## END networks
}
```
</p>
</details>


<details><summary>1x Network, 2x Cloud-Routers in 1x Region, 2x VPN-Tunnels, 2x Interconnect attachments</summary>
<p>

```hcl
module "network" {
  source  = "../modules/gcp-network"

  kms_crypto_key_name = "<kms_crypto_key_name>" # required for vpn_tunnels shared_secret KMS encryption
  kms_key_ring_name   = "<kms_key_ring_name>"   # required for vpn_tunnels shared_secret KMS encryption
  project_id          = "<project_id>"
  
  networks   = {
      "network-name" = {
          auto_create_subnetworks = false
          description             = "Example network"
          routing_mode            = "REGIONAL"

          subnets = {
              "subnet-name" = {
                  ip_cidr_range            = "10.100.1.0/24"
                  enable_flow_logs         = true
                  private_ip_google_access = true
                  region                   = "us-west2"
              }
          }

          cloud_routers = {
              "us-west2" = {
                  "primary" = {
                      bgp = {
                          asn                  = "<cloud_router_asn>"
                          advertise_mode       = "CUSTOM"
                          advertised_groups    = [ "ALL_SUBNETS" ]
                          advertised_ip_ranges = [ "10.100.0.0/16", "10.101.0.0/16" ]
                      }

                      ic_attachments = {
                          "ic-link-us-west2-pri" = {
                              candidate_subnets   = "[ <candidate_subnets> ]"
                              interconnect_url    = "<my-interconnect-id>"
                              peer_ip_address     = "<peer_ip_address>"
                              peer_asn            = "<peer_asn>"
                              router_int_ip_range = "<ip_range>"
                              type                = "DEDICATED"
                              vlan_tag8021q       = "<tag>"
                          }

                          "ic-link-us-west2-sec" = {
                              candidate_subnets   = "[ <candidate_subnets> ]"
                              interconnect_url    = "<my-interconnect-id>"
                              peer_ip_address     = "<peer_ip_address>"
                              peer_asn            = "<peer_asn>"
                              router_int_ip_range = "<ip_range>"
                              type                = "DEDICATED"
                              vlan_tag8021q       = "<tag>"
                          }
                      } ## END ic_attachments

                      nat_gateway = {
                          icmp_idle_timeout_sec            = 30
                          log_enable                       = true
                          log_filter                       = "TRANSLATIONS_ONLY"
                          tcp_established_idle_timeout_sec = 1200
                          tcp_transitory_idle_timeout_sec  = 30
                          udp_idle_timeout_sec             = 30
                      }

                  } ## END primary

                  "secondary" = {
                      bgp = {
                          asn = "<cloud_router_asn>"
                      }

                      vpn_tunnels = {
                          "tunnel-1" = {
                              peer_asn              = "<peer_asn>"
                              peer_ip_address       = "<peer_ip_address>"
                              peer_vpngw_ip_address = "<peer_ip_address>"
                              router_int_ip_range   = "<ip_range>"
                              shared_secret_cipher  = "<kms_secret_ciphertext>"
                          }

                          "tunnel-2" = {
                              peer_asn              = "<peer_asn>"
                              peer_ip_address       = "<peer_ip_address>"
                              peer_vpngw_ip_address = "<peer_ip_address>"
                              router_int_ip_range   = "<ip_range>"
                              shared_secret_cipher  = "<kms_secret_ciphertext>"
                          }
                      } ## END vpn_tunnels
                  } ## END secondary
              } ## END us-west2
          } ## END cloud_routers
      } ## END network-name
  } ## END networks
}
```
</p>
</details>

<details><summary>Full-fledged example</summary>
<p>

```hcl
module "network" {
  source  = "../modules/gcp-network"

  is_xpn_host         = true                    # Make <project_id> a Shared VPC Host
  kms_crypto_key_name = "<kms_crypto_key_name>" # required for vpn_tunnels shared_secret KMS encryption
  kms_key_ring_name   = "<kms_key_ring_name>"   # required for vpn_tunnels shared_secret KMS encryption
  project_id          = "<project_id>"

  networks   = {
      "xpn-prod" = {
        auto_create_subnetworks = false
        description             = "Production Shared VPC Network"
        routing_mode            = "GLOBAL"

        ## START subnets
        subnets = {
            "usw2-pri" = {
              ip_cidr_range            = "10.100.10.0/24"
              enable_flow_logs         = true
              private_ip_google_access = true
              region                   = "us-west2"

              log_config = {
                  aggregation_interval = "INTERVAL_5_MIN"
                  flow_sampling        = 0.6
                  metadata             = "INCLUDE_ALL_METADATA"
              }

              secondary_ip_ranges = {
                  "test-sec-1" = "10.100.11.0/24"
                  "test-sec-2" = "10.100.12.0/24"
              }
            } ## END usw2-pri
        } ## END SUBNETS

        cloud_routers = {
            "us-west2" = {
                "primary" = {
                    bgp = {
                        asn = "60301"
                    }

                    vpn_tunnels = {
                        "losangeles1-a" = {
                            ike_version          = 1
                            peer_asn             = "60010"
                            peer_ip              = "133.21.34.57"
                            router_int_ip_range  = "169.254.1.1/30"
                            router_int_peer_ip   = "169.254.1.2"
                            shared_secret_cipher = "CiQAJe2a6lkXptEsL8n++Za8oSo52NCITsKH8DfxAJEKmVaaBa8SPQBiPJTErkyaegVmcOABhpoZHIowiU8sY6XytEBIj6aet7nIFpIJ3pg3rHroTU5TaEzQ8gol/FWu5C/sgks="
                        }
                    } ## END vpn_tunnels
                } ## END primary

                "secondary" = {
                    bgp = {
                        asn = "60301"
                    }

                    vpn_tunnels = {
                        "losangeles1-b" = {
                            ike_version          = 1
                            peer_asn             = "60010"
                            peer_ip              = "133.21.34.59"
                            router_int_ip_range  = "169.254.1.5/30"
                            router_int_peer_ip   = "169.254.1.6"
                            shared_secret_cipher = "CiQAJe2a6lkXptEsL8n++Za8oSo52NCITsKH8DfxAJEKmVaaBa8SPQBiPJTErkyaegVmcOABhpoZHIowiU8sY6XytEBIj6aet7nIFpIJ3pg3rHroTU5TaEzQ8gol/FWu5C/sgks="
                        }
                    } ## END vpn_tunnels
                } ## END secondary
            } ## END us-west2
        } ## END ROUTERS

        firewall_rules = {
            /***********************
             EGRESS
            **********************/
            "default-egress-allow-to-cidr-aws-gcp" = {
                description        = "DEFAULT|EGRESS - ALLOW all outbound traffic to PROD GCP & AWS subnets"
                direction          = "EGRESS"
                priority           = 65490

                allow = {
                    "icmp"         = []
                    "tcp"          = []
                    "udp"          = []
                }

                destination_ranges = [ "10.100.0.0/15",
                                       "10.200.0.0/15" ]

            }


            "default-egress-deny-to-cidr-onprem" = {
                description        = "DEFAULT|EGRESS - DENY all outbound traffic to on-prem subnets"
                direction          = "EGRESS"
                priority           = 65500

                deny = {
                    "icmp"         = []
                    "tcp"          = []
                    "udp"          = []
                }

                destination_ranges = [ "10.0.0.0/8",
                                       "192.168.0.0/16",
                                       "172.16.0.0/12", ]
            }

            /***********************
             INGRESS
            **********************/
            "ingress-allow-tag-lb-health-checks" = {
                description   = "SELFSERVICE|INGRESS - ALLOW health checks from HTTP(S), SSL/TCP Proxy and Internal HTTP(s)/TCP/UDP Load Balancers"
                direction     = "INGRESS"
                priority      = 10

                allow = {
                    "tcp"     = []
                }

                source_ranges = [ "35.191.0.0/16",
                                  "130.211.0.0/22", ]

                target_tags   = [ "allow-health-checks-from-lb" ]
            }


            # see https://cloud.google.com/load-balancing/docs/health-checks#fw-netlb for reference
            "ingress-allow-tag-network-lb-health-checks" = {
                description   = "SELFSERVICE|INGRESS - ALLOW legacy health checks from Network Load Balancers"
                direction     = "INGRESS"
                priority      = 10

                allow = {
                    "tcp"     = []
                }

                source_ranges = [ "35.191.0.0/16",
                                  "209.85.152.0/22",
                                  "209.85.204.0/22", ]

                target_tags   = [ "allow-health-checks-from-network-lb" ]
            }


            "default-ingress-deny-from-cidr-aws-gcp" = {
                description   = "DEFAULT|INGRESS - DENY all incoming traffic from PROD GCP & AWS Subnets"
                direction     = "INGRESS"
                priority      = 65490

                deny = {
                    "icmp"    = []
                    "tcp"     = []
                    "udp"     = []
                }

                source_ranges = [ "10.100.0.0/15",
                                  "10.200.0.0/15", ]
            }


            "default-ingress-allow-from-cidr-onprem" = {
                description   = "DEFAULT|INGRESS - ALLOW ICMP and ssh incoming traffic from on-prem Subnets"
                direction     = "INGRESS"
                priority      = 65500

                allow = {
                    "icmp"    = []
                    "tcp"     = [ "22", ]
                }

                source_ranges = [ "10.0.0.0/8",
                                  "192.168.0.0/16",
                                  "172.16.0.0/12", ]
            }
        } ## END firewall_rules
     } ## END prod-xpn
  } ## END networks
}
```
</p>
</details>

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| is\_auto\_network | When set to true, automatically create default network with a /20 subnet (w/ flow logging enabled) for each GCP region across the 10.128.0.0/9 address range | bool | `"false"` | no |
| is\_xpn\_host | Makes this project a Shared VPC host if true (default false) | bool | `"false"` | no |
| kms\_crypto\_key\_name | KMS CryptoKey name | string | `""` | no |
| kms\_key\_ring\_name | KMS KeyRing name | string | `""` | no |
| networks | Map of maps defining VPC networks and their associated resources per region | any | `{}` | no |
| project\_id | Target Project (id) | string | n/a | yes |
| xpn\_firewall\_rules | Map of maps defining firewall rules to create in Shared VPC host network | any | `{}` | no |
| xpn\_host\_network\_name | Shared VPC host network name | string | `""` | no |
| xpn\_host\_project\_id | Shared VPC host project ID | string | `""` | no |
| xpn\_networkUser\_members | List of user(s), group(s) and service account(s) to grant NetworkUser role on xpn_subnets | list(string) | `[]` | no |
| xpn\_subnets | Map of maps defining subnetworks to create in Shared VPC host network | any | `{}` | no |
| xpn\_subnets\_label | Label to associate with subnets created in Shared VPC host network | string | `"subnet"` | no |

## Outputs

| Name | Description |
|------|-------------|
| cloud\_routers | Map of cloud-routers maps per network |
| firewall\_rules | Map of Firewall rules maps per network |
| interconnect\_attachments | Map of IC attachments maps per network/cloud-router |
| interconnect\_attachments\_routers\_interfaces | Map of IC attachements routers interfaces maps per network/cloud-router |
| interconnect\_attachments\_routers\_interfaces\_peers | Map of IC attachments routers interfaces peers maps per network/cloud-router |
| nat\_gateways | Map of nat-gateways maps per network |
| networks | Map of networks maps |
| routes | Map of routes maps per network |
| subnets | Map of subnets maps per network |
| vpn\_gateways | Map of vpn-gateways maps per network/cloud-router |
| vpn\_tunnels | Map of vpn-tunnels maps per network/cloud-router |
| vpn\_tunnels\_routers\_interfaces | Map of vpn-tunnels routers interfaces maps per network/cloud-router |
| vpn\_tunnels\_routers\_interfaces\_peers | Map of vpn-tunnels routers interfaces peers maps per network/cloud-router |
| xpn\_firewall\_rules | Map of firewall rules maps on XPN host network |
| xpn\_subnets | Map of subnets maps on XPN host network |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Arguments references
- `networks`:
  - https://www.terraform.io/docs/providers/google/r/compute_network.html#argument-reference

- `firewall_rules`:
  - https://www.terraform.io/docs/providers/google/r/compute_firewall.html#argument-reference

- `cloud_routers`:
  - `bgp`:
    - https://www.terraform.io/docs/providers/google/r/compute_router.html#argument-reference
  - `ic_attachments`:
    - https://www.terraform.io/docs/providers/google/r/compute_interconnect_attachment.html#argument-reference
    - https://www.terraform.io/docs/providers/google/r/compute_router_interface.html#argument-reference
    - https://www.terraform.io/docs/providers/google/r/compute_router_peer.html#argument-reference
  - `nat_gateway`:
    - https://www.terraform.io/docs/providers/google/r/compute_router_nat.html#argument-reference
  - `vpn_tunnels`:
    - https://www.terraform.io/docs/providers/google/r/compute_vpn_tunnel.html#argument-reference
    - https://www.terraform.io/docs/providers/google/r/compute_router_interface.html#argument-reference
    - https://www.terraform.io/docs/providers/google/r/compute_router_peer.html#argument-reference

- `routes`:
  - https://www.terraform.io/docs/providers/google/r/compute_route.html#argument-reference

- `subnets`:
  - https://www.terraform.io/docs/providers/google/r/compute_subnetwork.html#argument-reference

## Requirements
### Terraform plugins
- [Terraform](https://www.terraform.io/downloads.html) >= 0.12.6
- [terraform-provider-google](https://github.com/terraform-providers/terraform-provider-google) >= v2.5.0
- [terraform-provider-google-beta](https://github.com/terraform-providers/terraform-provider-google-beta) >= v2.5.0

### Permissions
In order to execute this module, the Service Account you run as must have the **Compute Network Admin** (`roles/compute.networkAdmin`) role on the target project.

