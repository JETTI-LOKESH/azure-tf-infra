# Operational Runbook

This runbook covers deployment, health verification, secret rotation, and VM failure recovery procedures.

---

## 1. Deploy from Scratch

### Prerequisites
- Azure CLI authenticated (`az login`)
- Terraform >= 1.5.0 installed
- Access to an Azure subscription with Contributor role

### Steps

```bash
# 1. Clone the repository
git clone <repo-url>
cd azure-infra-assessment/terraform

# 2. Create variable file
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars — set allowed_ssh_cidr to your IP

# 3. Initialize Terraform
terraform init

# 4. Review the plan
terraform plan -out=tfplan

# 5. Apply infrastructure
terraform apply tfplan

# 6. Note outputs
terraform output
```

### Post-Deploy Verification
```bash
# Wait 2-3 minutes for VM startup script to complete
PUBLIC_IP=$(terraform output -raw public_ip_address)

# Test HTTPS endpoint
curl -k https://$PUBLIC_IP/health
# Expected: {"status":"ok"}

# Test main endpoint
curl -k https://$PUBLIC_IP/
# Expected: {"status":"healthy","service":"infra-assessment",...}
```

---

## 2. Health Verification

### Automated Checks

| Check | Command | Expected |
|-------|---------|----------|
| VM running | `az vm show -g rg-infra-assessment -n vm-infra-assessment --query powerState` | `"VM running"` |
| HTTPS responds | `curl -k -o /dev/null -s -w "%{http_code}" https://<IP>/health` | `200` |
| Key Vault accessible | `az keyvault secret list --vault-name <kv-name> --query "[].name"` | List of secrets |
| NSG rules | `az network nsg rule list -g rg-infra-assessment --nsg-name nsg-app-infra-assessment -o table` | 3 rules |

### Manual Health Check Script
```bash
#!/bin/bash
PUBLIC_IP=$(az vm list-ip-addresses -g rg-infra-assessment -n vm-infra-assessment \
  --query "[0].virtualMachine.network.publicIpAddresses[0].ipAddress" -o tsv)

echo "Testing HTTPS endpoint..."
HTTP_CODE=$(curl -k -o /dev/null -s -w "%{http_code}" https://$PUBLIC_IP/health)

if [ "$HTTP_CODE" == "200" ]; then
  echo "✅ Service is healthy (HTTP $HTTP_CODE)"
else
  echo "❌ Service is unhealthy (HTTP $HTTP_CODE)"
  exit 1
fi
```

---

## 3. Key Vault Secret Rotation

### When to Rotate
- TLS certificate is within 30 days of expiry (alert will fire)
- Scheduled rotation every 90 days
- After any security incident

### Rotation Procedure

```bash
KV_NAME=$(terraform output -raw keyvault_name)

# 1. Generate new secret value
NEW_SECRET=$(openssl rand -base64 32)

# 2. Update the secret in Key Vault
az keyvault secret set \
  --vault-name $KV_NAME \
  --name "tls-cert-password" \
  --value "$NEW_SECRET" \
  --expires $(date -u -d "+90 days" +%Y-%m-%dT%H:%M:%SZ)

# 3. Verify the new secret version
az keyvault secret show \
  --vault-name $KV_NAME \
  --name "tls-cert-password" \
  --query "{name:name, version:id, expires:attributes.expires}"

# 4. Restart the service on the VM to pick up new certs (if applicable)
az vm run-command invoke \
  -g rg-infra-assessment \
  -n vm-infra-assessment \
  --command-id RunShellScript \
  --scripts "systemctl restart nginx"

# 5. Verify service is still healthy
curl -k https://$PUBLIC_IP/health
```

### SSH Key Rotation
```bash
# Generate new SSH keypair
ssh-keygen -t rsa -b 4096 -f ~/.ssh/new_key -N ""

# Update VM with new key
az vm user update \
  -g rg-infra-assessment \
  -n vm-infra-assessment \
  -u azureuser \
  --ssh-key-value "$(cat ~/.ssh/new_key.pub)"

# Store new private key in Key Vault
az keyvault secret set \
  --vault-name $KV_NAME \
  --name "vm-ssh-private-key" \
  --file ~/.ssh/new_key
```

---

## 4. Recovery from VM Failure

### Scenario: VM is Unresponsive

```bash
# 1. Check VM status
az vm get-instance-view \
  -g rg-infra-assessment \
  -n vm-infra-assessment \
  --query "instanceView.statuses[1].displayStatus"

# 2. Attempt restart
az vm restart -g rg-infra-assessment -n vm-infra-assessment

# 3. Wait 2 minutes, then verify
sleep 120
curl -k https://$PUBLIC_IP/health
```

### Scenario: VM Restart Fails

```bash
# 1. Deallocate and restart
az vm deallocate -g rg-infra-assessment -n vm-infra-assessment
az vm start -g rg-infra-assessment -n vm-infra-assessment

# 2. If still failing, check boot diagnostics
az vm boot-diagnostics get-boot-log \
  -g rg-infra-assessment \
  -n vm-infra-assessment
```

### Scenario: Full Rebuild Required

```bash
# 1. Taint the VM resource to force recreation
cd terraform
terraform taint 'module.compute.azurerm_linux_virtual_machine.this'

# 2. Plan and apply
terraform plan -out=tfplan
terraform apply tfplan

# 3. Wait for startup script to complete (2-3 min)
# 4. Verify health
curl -k https://$(terraform output -raw public_ip_address)/health
```

### Scenario: Complete Infrastructure Recovery

```bash
# If the entire resource group is lost or corrupted:
cd terraform
terraform destroy -auto-approve  # Clean up any partial state
terraform apply -auto-approve    # Full redeploy

# Estimated recovery time: 5-8 minutes
```

---

## 5. Escalation Matrix

| Severity | Condition | Action | Timeline |
|----------|-----------|--------|----------|
| P1 | Service completely down | VM restart → rebuild | 15 min |
| P2 | Intermittent failures | Check logs, restart nginx | 30 min |
| P3 | Secret expiry warning | Rotate within business hours | 24 hours |
| P4 | Non-critical alert | Investigate next sprint | 1 week |

---

## 6. Useful Commands Reference

```bash
# SSH into VM (retrieve key from Key Vault)
KV_NAME=$(terraform output -raw keyvault_name)
az keyvault secret download --vault-name $KV_NAME --name vm-ssh-private-key --file /tmp/ssh_key
chmod 600 /tmp/ssh_key
ssh -i /tmp/ssh_key azureuser@$(terraform output -raw public_ip_address)

# View VM startup script logs
az vm run-command invoke \
  -g rg-infra-assessment -n vm-infra-assessment \
  --command-id RunShellScript \
  --scripts "cat /var/log/startup-script.log"

# Check nginx status on VM
az vm run-command invoke \
  -g rg-infra-assessment -n vm-infra-assessment \
  --command-id RunShellScript \
  --scripts "systemctl status nginx"
```
