# Azure FinOps & Security Drift Audit Report
- **Subscription:** Azure subscription 1 (286ff1db-ddbc-48a8-a997-b62be663610b)
- **Audit Date (UTC):** 2026-11-19 01:08:18 UTC

---

## 1. FinOps: Orphaned & Idle Resources (Cost Leaks)
### Unattached Managed Disks
✅ No unattached disks found.

### Unassociated Public IPs
✅ No unassociated Public IPs found.

---

## 2. Security Posture: Compliance & Misconfigurations
### Storage Accounts with Public Blob Access Enabled
✅ All storage accounts block public blob access.

### High-Risk NSG Rules (Exposed SSH/RDP to Internet)
✅ No NSGs exposing ports 22 or 3389 to the public internet.
