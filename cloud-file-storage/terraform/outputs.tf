output "resource_group_name" {
  description = "Resource group name"
  value       = azurerm_resource_group.main.name
}

output "aks_cluster_name" {
  description = "AKS cluster name"
  value       = azurerm_kubernetes_cluster.main.name
}

output "storage_account_name" {
  description = "Storage account name"
  value       = azurerm_storage_account.main.name
}

output "cosmos_endpoint" {
  description = "Cosmos DB endpoint"
  value       = azurerm_cosmosdb_account.main.endpoint
}

output "apim_gateway_url" {
  description = "API Management gateway URL"
  value       = azurerm_api_management.main.gateway_url
}

output "frontdoor_endpoint" {
  description = "Front Door endpoint"
  value       = azurerm_cdn_frontdoor_endpoint.main.host_name
}

output "keyvault_name" {
  description = "Key Vault name"
  value       = azurerm_key_vault.main.name
}

output "keyvault_uri" {
  description = "Key Vault URI"
  value       = azurerm_key_vault.main.vault_uri
}

output "aks_oidc_issuer_url" {
  description = "AKS OIDC Issuer URL (for workload identity)"
  value       = azurerm_kubernetes_cluster.main.oidc_issuer_url
}
