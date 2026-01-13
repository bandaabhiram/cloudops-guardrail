package guardrails.azure

# Deny SSH open to the world
deny[msg] {
  rc := input.resource_changes[_]
  rc.type == "azurerm_network_security_group"
  rule := rc.change.after.security_rule[_]
  rule.direction == "Inbound"
  rule.access == "Allow"
  rule.destination_port_range == "22"
  rule.source_address_prefix == "*"
  msg := "DENY: NSG allows SSH from the Internet (*). Restrict to trusted CIDR."
}

# Require HTTPS-only on storage
deny[msg] {
  rc := input.resource_changes[_]
  rc.type == "azurerm_storage_account"
  after := rc.change.after
  after.enable_https_traffic_only == false
  msg := "DENY: Storage must enforce HTTPS-only (enable_https_traffic_only=true)."
}

# Require TLS 1.2 minimum on storage
deny[msg] {
  rc := input.resource_changes[_]
  rc.type == "azurerm_storage_account"
  after := rc.change.after
  after.min_tls_version != "TLS1_2"
  msg := "DENY: Storage must require TLS 1.2 minimum (min_tls_version='TLS1_2')."
}

# Strong posture: disable public network access to storage
deny[msg] {
  rc := input.resource_changes[_]
  rc.type == "azurerm_storage_account"
  after := rc.change.after
  not after.public_network_access_enabled == false
  msg := "DENY: Storage should disable public network access (public_network_access_enabled=false)."
}
