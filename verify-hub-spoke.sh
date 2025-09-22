#!/bin/bash

# Azure Hub-Spoke Infrastructure Verification Script
# Run this after your hub-spoke deployment completes

set -e

# =============================================
# CONFIGURATION VARIABLES - UPDATE THESE
# =============================================
RESOURCE_GROUP="rg-hub-spoke-westus3"  # Change this to your resource group name
HUB_GATEWAY="vng-hub01"
ONPREM_GATEWAY="vng-onprem01"

# =============================================
# SPINNER FUNCTIONS
# =============================================

# Function to show a spinning wheel
spinner() {
    local pid=$!
    local delay=0.1
    local spinchars="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
    while ps -p $pid > /dev/null; do
        for i in $(seq 0 9); do
            if ps -p $pid > /dev/null; then
                printf "\r%s %s" "${spinchars:$i:1}" "$1"
                sleep $delay
            fi
        done
    done
    printf "\r%s ✅\n" "$1"
}

# Function to run command with spinner
run_with_spinner() {
    local message="$1"
    shift
    "$@" > /tmp/az_output 2>&1 &
    spinner "$message"
    wait
    cat /tmp/az_output
    rm -f /tmp/az_output
}

echo "=============================================="
echo ""
echo "        ☁️  ☁️  ☁️  ☁️  ☁️"
echo "      ☁️  ☁️  AZURE  ☁️  ☁️"
echo "      Hub & Spoke Verification"
echo ""
echo "                                Spoke1"
echo "                                  |"
echo "    OnPrem ====== Internet ====== 🔥Hub"
echo "                                  |"
echo "                                Spoke2"
echo ""
echo "=============================================="
echo ""
echo "Resource Group: $RESOURCE_GROUP"
echo "Timestamp: $(date)"
echo ""

# Check if resource group exists
echo ""
run_with_spinner "📋 Verifying resource group exists... " az group show --name $RESOURCE_GROUP --output none
echo "✅ Resource group '$RESOURCE_GROUP' found"

echo ""
echo "🔗 VPN Connection Status"
echo "========================"
run_with_spinner "Checking VPN connections... " az network vpn-connection list \
    --resource-group $RESOURCE_GROUP \
    --output table \
    --query "[].{Name:name, Status:connectionStatus, SharedKey:sharedKey, EnableBgp:enableBgp}"

echo ""
echo "🌐 Hub Gateway BGP Peer Status"
echo "=============================="
echo "Hub Gateway: $HUB_GATEWAY"
run_with_spinner "Checking Hub BGP peers... " az network vnet-gateway list-bgp-peer-status \
    --resource-group $RESOURCE_GROUP \
    --name $HUB_GATEWAY \
    --output table 2>/dev/null || echo "BGP peer status not available yet - connections may still be establishing"

echo ""
echo "🏢 OnPrem Gateway BGP Peer Status"
echo "================================="
echo "OnPrem Gateway: $ONPREM_GATEWAY"
run_with_spinner "Checking OnPrem BGP peers... " az network vnet-gateway list-bgp-peer-status \
    --resource-group $RESOURCE_GROUP \
    --name $ONPREM_GATEWAY \
    --output table 2>/dev/null || echo "BGP peer status not available yet - connections may still be establishing"

echo ""
echo "📡 Hub Gateway Learned BGP Routes"
echo "================================="
echo "Routes learned by Hub Gateway:"
run_with_spinner "Getting Hub BGP routes... " az network vnet-gateway list-learned-routes \
    --resource-group $RESOURCE_GROUP \
    --name $HUB_GATEWAY \
    --output table \
    --query "value[].{Network:network, NextHop:nextHop, Origin:origin, AsPath:asPath}" 2>/dev/null || echo "BGP routes not available yet"

echo ""
echo "📡 OnPrem Gateway Learned BGP Routes" 
echo "===================================="
echo "Routes learned by OnPrem Gateway:"
run_with_spinner "Getting OnPrem BGP routes... " az network vnet-gateway list-learned-routes \
    --resource-group $RESOURCE_GROUP \
    --name $ONPREM_GATEWAY \
    --output table \
    --query "value[].{Network:network, NextHop:nextHop, Origin:origin, AsPath:asPath}" 2>/dev/null || echo "BGP routes not available yet"

echo ""
echo "🔥 Azure Firewall Status"
echo "========================"
run_with_spinner "Checking Azure Firewall... " az network firewall show \
    --resource-group $RESOURCE_GROUP \
    --name fw-hub01 \
    --output table \
    --query "{Name:name, State:provisioningState, PrivateIP:ipConfigurations[0].privateIpAddress, PublicIP:ipConfigurations[0].publicIpAddress.id}"

echo ""
echo "🏰 Azure Bastion Status"
echo "======================="
run_with_spinner "Checking Azure Bastion... " az network bastion show \
    --resource-group $RESOURCE_GROUP \
    --name bastion-hub01 \
    --output table \
    --query "{Name:name, State:provisioningState, SKU:sku.name}"

echo ""
echo "💻 Virtual Machines Status"
echo "=========================="
run_with_spinner "Checking VM status... " az vm list \
    --resource-group $RESOURCE_GROUP \
    --output table \
    --query "[].{Name:name, PowerState:powerState, PrivateIP:privateIps, Location:location}"

echo ""
echo "🛣️ Route Tables"
echo "==============="
echo "Spoke01 Route Table:"
run_with_spinner "Checking Spoke01 routes... " az network route-table route list \
    --resource-group $RESOURCE_GROUP \
    --route-table-name rt-spoke01 \
    --output table \
    --query "[].{Name:name, AddressPrefix:addressPrefix, NextHopType:nextHopType, NextHopIP:nextHopIpAddress}" 2>/dev/null || echo "Route table not found"

echo ""
echo "Spoke02 Route Table:"
run_with_spinner "Checking Spoke02 routes... " az network route-table route list \
    --resource-group $RESOURCE_GROUP \
    --route-table-name rt-spoke02 \
    --output table \
    --query "[].{Name:name, AddressPrefix:addressPrefix, NextHopType:nextHopType, NextHopIP:nextHopIpAddress}" 2>/dev/null || echo "Route table not found"

echo ""
echo "🔍 Summary & Recommendations"
echo "============================"
echo "✅ Infrastructure verification complete"
echo ""
echo "Next Steps:"
echo "1. 🔑 Change VM passwords immediately"
echo "2. 🧪 Test connectivity using Azure Bastion:"
echo "   - Connect to vm-onprem-01 and ping spoke VMs at 10.0.2.x, 10.0.3.x"
echo "   - Connect to spoke VMs and test internet access via firewall"
echo "3. 🔒 Replace firewall Allow All rules with specific security rules"
echo "4. 📊 Set up monitoring and logging for production use"
echo ""
echo "Connection Testing Commands:"
echo "# From vm-onprem-01, test connectivity:"
echo "ping 10.0.2.4        # Spoke01 VM"
echo "ping 10.0.3.4        # Spoke02 VM"
echo ""
echo "# From spoke VMs, test connectivity:"
echo "ping 192.168.0.132   # OnPrem VM"
echo ""
echo "# Test internet connectivity from any VM:"
echo "curl ipinfo.io       # Internet via firewall"
echo ""
echo "# To find actual VM IPs:"
echo "az vm list-ip-addresses -g $RESOURCE_GROUP --output table"
echo ""
echo "Verification completed at: $(date)"