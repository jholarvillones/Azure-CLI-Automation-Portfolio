#!/usr/bin/env bash
# ==============================================================================
# Script Name: provision_identity_rbac.sh
# Description: Automated Entra ID Group & Least-Privilege RBAC Governance Engine
# ==============================================================================

set -euo pipefail

CSV_FILE="hr_onboarding_feed.csv"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
AUDIT_LOG="logs/rbac_governance_audit_${TIMESTAMP}.log"
SUBSCRIPTION_ID=$(az account show --query "id" -o tsv)

echo "==================================================================" | tee -a "$AUDIT_LOG"
echo " Starting Automated Identity & RBAC Governance Run" | tee -a "$AUDIT_LOG"
echo " Target Subscription: $SUBSCRIPTION_ID" | tee -a "$AUDIT_LOG"
echo " Timestamp (UTC): $(date -u +"%Y-%m-%d %H:%M:%S UTC")" | tee -a "$AUDIT_LOG"
echo "==================================================================" | tee -a "$AUDIT_LOG"

# Read CSV skipping header
tail -n +2 "$CSV_FILE" | while IFS=',' read -r DISPLAY_NAME UPN_PREFIX DEPT JOB_TITLE RBAC_ROLE; do
    GROUP_NAME="SG-Azure-${DEPT}"
    GROUP_NICKNAME=$(echo "$GROUP_NAME" | tr '[:upper:]' '[:lower:]' | tr -cd '[:alnum:]')

    echo "[INFO] Processing Employee: $DISPLAY_NAME ($JOB_TITLE) -> Dept: $DEPT" | tee -a "$AUDIT_LOG"

    # 1. Idempotent Security Group Creation
    GROUP_ID=$(az ad group list --display-name "$GROUP_NAME" --query "[0].id" -o tsv)
    if [ -z "$GROUP_ID" ]; then
        echo "  [+] Creating Entra ID Security Group: $GROUP_NAME" | tee -a "$AUDIT_LOG"
        GROUP_ID=$(az ad group create --display-name "$GROUP_NAME" --mail-nickname "$GROUP_NICKNAME" --query "id" -o tsv)
    else
        echo "  [=] Security Group already exists: $GROUP_NAME ($GROUP_ID)" | tee -a "$AUDIT_LOG"
    fi

    # 2. Enforce Least-Privilege RBAC Role Assignment at Subscription Scope
    echo "  [+] Enforcing RBAC Role '$RBAC_ROLE' on Group '$GROUP_NAME'" | tee -a "$AUDIT_LOG"
    az role assignment create \
        --assignee-object-id "$GROUP_ID" \
        --assignee-principal-type "Group" \
        --role "$RBAC_ROLE" \
        --scope "/subscriptions/$SUBSCRIPTION_ID" \
        --output none
        echo "    [WAIT] Waiting 15s for Entra ID replication..."
        sleep 15
        echo "    [WAIT] Waiting 15s for Entra ID replication..."
        sleep 15

    echo "  [SUCCESS] Governance policy applied for $DISPLAY_NAME." | tee -a "$AUDIT_LOG"
    echo "------------------------------------------------------------------" | tee -a "$AUDIT_LOG"
done

echo "Audit Log saved to: $AUDIT_LOG"
