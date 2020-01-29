/******************************************
  Locals configuration for module logic
 *****************************************/
locals {
  is_kms_setup   = var.kms_crypto_key_name != "" && var.kms_key_ring_name != ""
  is_xpn_service = length(var.xpn_subnets) > 0
}
