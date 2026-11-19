#!/usr/bin/env bash
# ==============================================================================
# Script Name: audit_azure.sh
# Description: Enterprise FinOps (Cost Waste) & Security Posture Auditor for Azure
# Author: Cloud Infrastructure & Security Portfolio
# ==============================================================================

set -euo pipefail

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
REPORT_FILE="reports/azure_audit_report_${TIMESTAMP}.md"
SUBSCRIPTION_NAME=$(az account show --query "name" -o tsv)
SUBSCRIPTION_ID=$(az account show --query "id" -o tsv)

echo "=================================================================="
echo " Starting Azure FinOps & Security Audit..."
echo " Target Subscription: $SUBSCRIPTION_NAME ($SUBSCRIPTION_ID)"
echo "=================================================================="

# Initialize Markdown Report
cat << HEADER > "$REPORT_FILE"
# Azure FinOps & Security Drift Audit Report
- **Subscription:** $SUBSCRIPTION_NAME ($SUBSCRIPTION_ID)
- **Audit Date (UTC):** $(date -u +"%Y-%m-%d %H:%M:%S UTC")

---

## 1. FinOps: Orphaned & Idle Resources (Cost Leaks)
HEADER

# 1. Check Unattached Managed Disks
echo "[1/4] Scanning for unattached managed disks..."
UNATTACHED_DISKS=$(az resource list --resource-type "Microsoft.Compute/disks" --query "[?properties.diskState=='Unattached'].{Name:name, ResourceGroup:resourceGroup, SizeGB:diskSizeGb, SKU:sku.name}" -o table)

echo "### Unattached Managed Disks" >> "$REPORT_FILE"
if [ -z "$UNATTACHED_DISKS" ]; then
    echo "✅ No unattached disks found." >> "$REPORT_FILE"
else
    echo '```text' >> "$REPORT_FILE"
    echo "$UNATTACHED_DISKS" >> "$REPORT_FILE"
    echo '```' >> "$REPORT_FILE"
fi

# 2. Check Unassociated Public IP Addresses
echo "[2/4] Scanning for unassociated Public IP addresses..."
UNUSED_IPS=$(az network public-ip list --query "[?ipConfiguration==null].{Name:name, ResourceGroup:resourceGroup, IPAddress:ipAddress, SKU:sku.name}" -o table)

echo -e "\n### Unassociated Public IPs" >> "$REPORT_FILE"
if [ -z "$UNUSED_IPS" ]; then
    echo "✅ No unassociated Public IPs found." >> "$REPORT_FILE"
else
    echo '```text' >> "$REPORT_FILE"
    echo "$UNUSED_IPS" >> "$REPORT_FILE"
    echo '```' >> "$REPORT_FILE"
fi

# 3. Security: Check Storage Accounts Allowing Public Blob Access
echo "[3/4] Auditing Storage Accounts for public blob access..."
PUBLIC_STORAGE=$(az storage account list --query "[?allowBlobPublicAccess==true`true``true`].{Name:name, ResourceGroup:resourceGroup, Location:location}" -o table)

cat << SEC_HEADER >> "$REPORT_FILE"

---

## 2. Security Posture: Compliance & Misconfigurations
### Storage Accounts with Public Blob Access Enabled
SEC_HEADER

if [ -z "$PUBLIC_STORAGE" ]; then
    echo "✅ All storage accounts block public blob access." >> "$REPORT_FILE"
else
    echo '```text' >> "$REPORT_FILE"
    echo "$PUBLIC_STORAGE" >> "$REPORT_FILE"
    echo '```' >> "$REPORT_FILE"
fi

# 4. Security: Check NSG Rules Exposing SSH (22) or RDP (3389) to the Internet
echo "[4/4] Auditing Network Security Groups for exposed management ports..."
EXPOSED_NSGS=$(az network nsg list --query "[].securityRules[?access=='Allow' && direction=='Inbound' && (sourceAddressPrefix=='*' || sourceAddressPrefix=='0.0.0.0/0' || sourceAddressPrefix=='Internet') && (destinationPortRange=='22' || destinationPortRange=='3389' || destinationPortRange=='*')].{RuleName:name, Port:destinationPortRange, Source:sourceAddressPrefix}" -o table)

echo -e "\n### High-Risk NSG Rules (Exposed SSH/RDP to Internet)" >> "$REPORT_FILE"
if [ -z "$EXPOSED_NSGS" ]; then
    echo "✅ No NSGs exposing ports 22 or 3389 to the public internet." >> "$REPORT_FILE"
else
    echo '```text' >> "$REPORT_FILE"
    echo "$EXPOSED_NSGS" >> "$REPORT_FILE"
    echo '```' >> "$REPORT_FILE"
fi

echo "=================================================================="
echo " Audit Complete! Report saved to: $REPORT_FILE"
echo "=================================================================="
