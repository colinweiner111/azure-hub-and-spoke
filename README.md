# Azure Hub-Spoke Network Infrastructure

Automated deployment and verification scripts for Azure hub-and-spoke network architecture with VPN connectivity and BGP routing.

## Requirements

**Azure CLI:** These scripts require Azure CLI to be installed and configured with appropriate Azure subscription permissions.

**Bash Environment:** The scripts are written in bash and require a bash shell environment. Options include:
- **Windows:** WSL (Windows Subsystem for Linux), Git Bash, or PowerShell with bash support
- **macOS/Linux:** Native terminal environment
- **Azure Cloud Shell:** Available but has 20-minute inactivity timeout

**Runtime Consideration:** The deployment script takes over 60 minutes to complete. For uninterrupted execution, avoid Azure Cloud Shell due to its timeout limitations.

## Scripts

### deploy-hub-spoke.sh
Automated Azure CLI script that deploys a complete hub-and-spoke network architecture.

**Features:**
- Hub VNet with Azure Firewall Premium
- Two spoke VNets with VM workloads
- Simulated on-premises environment
- Active/Active VPN gateways with BGP routing
- Site-to-site IPSec connections
- Azure Bastion for secure VM access
- Network security groups and route tables

**Deployment time:** ~60 minutes

### verify-hub-spoke.sh
Infrastructure verification script with animated status checks and network topology display.

**Verification includes:**
- VPN connection status and BGP peering
- Learned BGP routes from both gateways
- Azure Firewall and Bastion status
- VM power states and IP configurations
- Route table validation
- Connectivity testing guidance

## Prerequisites

- Azure CLI installed and configured
- Azure subscription with appropriate permissions
- Bash environment (Linux, macOS, or WSL)

## Usage

1. **Download the scripts:**
```bash
   # Download deployment script
   wget https://raw.githubusercontent.com/colinweiner111/azure-hub-and-spoke/main/deploy-hub-spoke.sh
   
   # Download verification script
   wget https://raw.githubusercontent.com/colinweiner111/azure-hub-and-spoke/main/verify-hub-spoke.sh
