# Monitoring and Alerting

## Overview

This deployment uses Azure Monitor to track infrastructure health with two alert rules:

1. **VM Availability Alert** — Detects when the VM becomes unreachable
2. **Key Vault Availability Alert** — Warns when Key Vault service has access issues

---

## Alert Rules

### 1. VM Availability (Severity 1 - Critical)

| Property | Value |
|----------|-------|
| Metric | `VmAvailabilityMetric` |
| Condition | Average < 1 over 5 minutes |
| Evaluation | Every 1 minute |
| Action | Notify via Action Group |

**Why this alert matters:**  
This is the most fundamental health signal. If the VM stops responding, the HTTPS service is down. A 5-minute window avoids false positives from transient Azure platform events while catching genuine outages quickly.

**Response:** Follow the VM Failure Recovery section in [RUNBOOK.md](./RUNBOOK.md#4-recovery-from-vm-failure).

---

### 2. Key Vault Availability (Severity 2 - Warning)

| Property | Value |
|----------|-------|
| Metric | `Availability` |
| Namespace | `Microsoft.KeyVault/vaults` |
| Condition | Average < 100% over 15 minutes |
| Evaluation | Every 5 minutes |
| Action | Notify via Action Group |

**Why this alert matters:**  
Key Vault availability dropping indicates access issues — the VM won't be able to retrieve secrets, TLS certs can't be rotated, and deployments may fail. This catches networking issues, throttling, or regional outages affecting the vault.

**Response:** Follow the Secret Rotation section in [RUNBOOK.md](./RUNBOOK.md#3-key-vault-secret-rotation). Check Azure Service Health for regional issues.

---

## Action Group

The action group `ag-infra-assessment` is configured as the notification target. To add email/SMS/webhook receivers:

```bash
# Add email receiver
az monitor action-group update \
  -g rg-infra-assessment \
  -n ag-infra-assessment \
  --add-action email admin admin@example.com

# Add webhook receiver
az monitor action-group update \
  -g rg-infra-assessment \
  -n ag-infra-assessment \
  --add-action webhook ops-webhook https://hooks.example.com/alert
```

---

## Extending Observability

### Recommended Additional Alerts (not deployed, for production consideration)

| Alert | Metric | Threshold |
|-------|--------|-----------|
| High CPU | `Percentage CPU` | > 80% for 10 min |
| Disk full | `OS Disk Used Percentage` | > 90% |
| Network drops | `Inbound Flows` | Drop to 0 for 5 min |
| Failed logins | Azure Activity Log | > 5 failed SSH attempts |

### Log Analytics Workspace (Deployed)

A Log Analytics workspace (`law-infra-assessment`) is deployed as part of the monitoring module. It receives:
- Key Vault audit logs via diagnostic settings
- AllMetrics from Key Vault

This enables:
- Centralized log collection
- Custom KQL queries for troubleshooting
- Dashboard creation in Azure Portal

---

## Viewing Alerts in Azure Portal

1. Navigate to **Monitor** → **Alerts**
2. Filter by resource group: `rg-infra-assessment`
3. View alert history and state (fired/resolved)

## CLI Alert Inspection

```bash
# List all alert rules
az monitor metrics alert list -g rg-infra-assessment -o table

# Check fired alerts
az monitor alert list -g rg-infra-assessment --query "[?monitorCondition=='Fired']" -o table
```
