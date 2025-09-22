```markdown
# Azure Hub-Spoke Network Infrastructure

Automated deployment and verification scripts for Azure hub-and-spoke network architecture with VPN connectivity and BGP routing.

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

### verify-hubspoke.sh
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

1. **Deploy infrastructure:**
   ```bash
   chmod +x deploy-hub-spoke.sh
   ./deploy-hub-spoke.sh
   ```

2. **Verify deployment:**
   ```bash
   chmod +x verify-hubspoke.sh
   # Update RESOURCE_GROUP variable in script
   ./verify-hubspoke.sh
   ```

## Architecture

```
                    Spoke1
                      |
OnPrem ====== Internet ====== 🔥Hub
                      |
                    Spoke2
```

**Network Details:**
- Hub: 10.0.0.0/23
- Spoke1: 10.0.2.0/24
- Spoke2: 10.0.3.0/24
- OnPrem: 192.168.0.0/24
- BGP ASNs: Hub (65509), OnPrem (65510)

## Security Notes

- Default VM passwords included for testing only
- Firewall configured with "Allow All" rules for lab use
- Replace with production security rules before use
```

Just copy everything between the code fences and paste it into your README.md file on GitHub.
