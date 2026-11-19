# Project 01: Enterprise Azure FinOps & Security Drift Auditor

## Business Problem
In dynamic cloud environments, engineering teams frequently leave behind orphaned resources (unattached managed disks, idle public IPs) after testing or decommissioning workloads, leading to unnecessary monthly cloud spend. Additionally, misconfigured Network Security Groups (NSGs) or public storage blobs introduce critical attack vectors.

## Solution
An automated, read-only **Azure CLI (Bash)** auditing engine that scans an entire Azure subscription to identify cost leaks and security drift, compiling findings into a timestamped Markdown compliance report.

## Key Capabilities
- **FinOps Cost Optimization:** Detects unattached managed disks and unassociated public IP addresses.
- **Zero-Trust Security Auditing:** Flags storage accounts permitting public blob access and NSG rules exposing management ports (`SSH/22`, `RDP/3389`) to the public internet (`0.0.0.0/0`).
- **Automated Reporting:** Generates clean, version-controllable Markdown reports inside `/reports`.

## Usage
```bash
chmod +x audit_azure.sh
./audit_azure.sh
```
