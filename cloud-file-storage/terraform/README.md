# Cloud File Storage - Azure Terraform

Simple Terraform configuration to deploy the cloud file storage infrastructure on Azure.

## What Gets Deployed

- **AKS** - Kubernetes cluster for running your services
- **API Management** - API gateway with auth and rate limiting  
- **Blob Storage** - File storage
- **Cosmos DB** - MongoDB-compatible database for metadata
- **Front Door** - CDN for fast file downloads
- **Key Vault** - Secrets management
- **Virtual Network** - Networking and security

**Estimated Cost:** ~$200-300/month

## Quick Start

### 1. Prerequisites

```bash
# Install Azure CLI and Terraform
az login
az account set --subscription "YOUR_SUBSCRIPTION"
```

### 2. Configure

```bash
cd cloud-file-storage/terraform

# Copy example file
cp terraform.tfvars.example terraform.tfvars

# Edit and set your email
notepad terraform.tfvars
```

### 3. Deploy

```bash
terraform init
terraform plan
terraform apply
```

Deployment takes about 30-45 minutes (APIM is slow to provision).

### 4. Connect to AKS

```bash
az aks get-credentials \
  --resource-group $(terraform output -raw resource_group_name) \
  --name $(terraform output -raw aks_cluster_name)

kubectl get nodes
```

## Configuration

Edit `terraform.tfvars`:

```hcl
project_name         = "cloudfs"           # Short name, lowercase
environment          = "dev"
location             = "eastus"
apim_publisher_email = "you@example.com"   # REQUIRED
```

## Outputs

After deployment:

```bash
terraform output              # View all outputs
terraform output apim_gateway_url
terraform output frontdoor_endpoint
```

## Cleanup

```bash
terraform destroy
```

⚠️ This deletes everything including all data!

## Azure Services Used

| Service | Purpose | Why This Choice |
|---------|---------|----------------|
| **AKS** | Container platform | Best for microservices (file, sync, share services) |
| **API Management** | API Gateway | Built-in auth, rate limiting, routing |
| **Blob Storage** | File storage | Handles large files, geo-redundant |
| **Cosmos DB (MongoDB)** | Metadata DB | Low latency, globally distributed |
| **Front Door** | CDN | Fast downloads, WAF protection |
| **Key Vault** | Secrets | Secure credential storage |

## Next Steps

1. Deploy your services to AKS
2. Configure API Management policies
3. Test file upload/download
4. Monitor in Azure Portal

## Support

- Check `main.tf` to see what resources are created
- Check `variables.tf` for all available options
- View Azure Portal for resource status
