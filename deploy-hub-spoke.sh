#!/bin/bash

# Azure Hub-Spoke Network Deployment Script
# Location: West US 3
# Hub: Hub01 (10.0.0.0/23)
# Spokes: Spoke01 (10.0.2.0/24), Spoke02 (10.0.3.0/24)

set -e

# Variables
LOCATION="westus3"
RESOURCE_GROUP="rg-hub-spoke-westus3"  # Edit this variable to match your resource group name
HUB_VNET="Hub01"
SPOKE01_VNET="Spoke01"
SPOKE02_VNET="Spoke02"
ONPREM_VNET="OnPrem01"

# IP Address Ranges
HUB_CIDR="10.0.0.0/23"
SPOKE01_CIDR="10.0.2.0/24"
SPOKE02_CIDR="10.0.3.0/24"
ONPREM_CIDR="192.168.0.0/24"

# Subnet Ranges
HUB_DEFAULT_SUBNET="10.0.0.0/26"
HUB_GATEWAY_SUBNET="10.0.0.64/26"
HUB_FIREWALL_SUBNET="10.0.0.128/26"
HUB_BASTION_SUBNET="10.0.0.192/26"
SPOKE01_DEFAULT_SUBNET="10.0.2.0/24"
SPOKE02_DEFAULT_SUBNET="10.0.3.0/24"
ONPREM_DEFAULT_SUBNET="192.168.0.0/26"
ONPREM_GATEWAY_SUBNET="192.168.0.64/26"
ONPREM_VM_SUBNET="192.168.0.128/26"

# VM Credentials (change these!)
ADMIN_USERNAME="azureuser"
ADMIN_PASSWORD="ChangeMePlease123!"

echo "🚀 Starting Azure Hub-Spoke Network Deployment..."
echo "📋 Using Resource Group: $RESOURCE_GROUP"
echo "⏰ Start Time: $(date)"

# Record start time
START_TIME=$(date +%s)

# Create Resource Group
echo "📦 Creating Resource Group..."
az group create \
  --name $RESOURCE_GROUP \
  --location $LOCATION

# Create Hub Virtual Network
echo "🌐 Creating Hub Virtual Network $HUB_VNET..."
az network vnet create \
  --resource-group $RESOURCE_GROUP \
  --name $HUB_VNET \
  --address-prefix $HUB_CIDR \
  --subnet-name default \
  --subnet-prefix $HUB_DEFAULT_SUBNET \
  --location $LOCATION

# Create Gateway Subnet for VPN Gateway
echo "🔒 Creating Gateway Subnet..."
az network vnet subnet create \
  --resource-group $RESOURCE_GROUP \
  --vnet-name $HUB_VNET \
  --name GatewaySubnet \
  --address-prefix $HUB_GATEWAY_SUBNET

# Create Azure Firewall Subnet
echo "🔥 Creating Azure Firewall Subnet..."
az network vnet subnet create \
  --resource-group $RESOURCE_GROUP \
  --vnet-name $HUB_VNET \
  --name AzureFirewallSubnet \
  --address-prefix $HUB_FIREWALL_SUBNET

# Create Azure Bastion Subnet
echo "🏰 Creating Azure Bastion Subnet..."
az network vnet subnet create \
  --resource-group $RESOURCE_GROUP \
  --vnet-name $HUB_VNET \
  --name AzureBastionSubnet \
  --address-prefix $HUB_BASTION_SUBNET

# Create Spoke01 Virtual Network
echo "🌐 Creating Spoke01 Virtual Network $SPOKE01_VNET..."
az network vnet create \
  --resource-group $RESOURCE_GROUP \
  --name $SPOKE01_VNET \
  --address-prefix $SPOKE01_CIDR \
  --subnet-name default \
  --subnet-prefix $SPOKE01_DEFAULT_SUBNET \
  --location $LOCATION

# Create Spoke02 Virtual Network
echo "🌐 Creating Spoke02 Virtual Network ($SPOKE02_VNET)..."
az network vnet create \
  --resource-group $RESOURCE_GROUP \
  --name $SPOKE02_VNET \
  --address-prefix $SPOKE02_CIDR \
  --subnet-name default \
  --subnet-prefix $SPOKE02_DEFAULT_SUBNET \
  --location $LOCATION

# Create OnPrem Virtual Network (simulates on-premises)
echo "🏢 Creating OnPrem Virtual Network ($ONPREM_VNET)..."
az network vnet create \
  --resource-group $RESOURCE_GROUP \
  --name $ONPREM_VNET \
  --address-prefix $ONPREM_CIDR \
  --subnet-name default \
  --subnet-prefix $ONPREM_DEFAULT_SUBNET \
  --location $LOCATION

# Create OnPrem Gateway Subnet
echo "🔒 Creating OnPrem Gateway Subnet..."
az network vnet subnet create \
  --resource-group $RESOURCE_GROUP \
  --vnet-name $ONPREM_VNET \
  --name GatewaySubnet \
  --address-prefix $ONPREM_GATEWAY_SUBNET

# Create OnPrem VM Subnet
echo "🏢 Creating OnPrem VM Subnet..."
az network vnet subnet create \
  --resource-group $RESOURCE_GROUP \
  --vnet-name $ONPREM_VNET \
  --name vm-subnet \
  --address-prefix $ONPREM_VM_SUBNET

# Create VNet Peering: Hub to Spoke01 (without gateway transit initially)
echo "🔗 Creating VNet Peering: Hub to Spoke01..."
az network vnet peering create \
  --resource-group $RESOURCE_GROUP \
  --name hub-to-spoke01 \
  --vnet-name $HUB_VNET \
  --remote-vnet $SPOKE01_VNET \
  --allow-vnet-access \
  --allow-forwarded-traffic

# Create VNet Peering: Spoke01 to Hub (without remote gateway initially)
echo "🔗 Creating VNet Peering: Spoke01 to Hub..."
az network vnet peering create \
  --resource-group $RESOURCE_GROUP \
  --name spoke01-to-hub \
  --vnet-name $SPOKE01_VNET \
  --remote-vnet $HUB_VNET \
  --allow-vnet-access \
  --allow-forwarded-traffic

# Create VNet Peering: Hub to Spoke02 (without gateway transit initially)
echo "🔗 Creating VNet Peering: Hub to Spoke02..."
az network vnet peering create \
  --resource-group $RESOURCE_GROUP \
  --name hub-to-spoke02 \
  --vnet-name $HUB_VNET \
  --remote-vnet $SPOKE02_VNET \
  --allow-vnet-access \
  --allow-forwarded-traffic

# Create VNet Peering: Spoke02 to Hub (without remote gateway initially)
echo "🔗 Creating VNet Peering: Spoke02 to Hub..."
az network vnet peering create \
  --resource-group $RESOURCE_GROUP \
  --name spoke02-to-hub \
  --vnet-name $SPOKE02_VNET \
  --remote-vnet $HUB_VNET \
  --allow-vnet-access \
  --allow-forwarded-traffic

# Create Public IPs for VPN Gateway (Active/Active)
echo "🌐 Creating Public IPs for VPN Gateway (Active/Active)..."
az network public-ip create \
  --resource-group $RESOURCE_GROUP \
  --name pip-vng-hub01-1 \
  --location $LOCATION \
  --allocation-method static \
  --sku standard

az network public-ip create \
  --resource-group $RESOURCE_GROUP \
  --name pip-vng-hub01-2 \
  --location $LOCATION \
  --allocation-method static \
  --sku standard

# Wait for public IPs to be fully ready
echo "⏳ Waiting for public IPs to be fully provisioned..."
sleep 30

# Verify public IPs were created successfully
echo "🔍 Verifying VPN Gateway public IPs were created..."
az network public-ip show --resource-group $RESOURCE_GROUP --name pip-vng-hub01-1 --query "id" -o tsv > /dev/null
az network public-ip show --resource-group $RESOURCE_GROUP --name pip-vng-hub01-2 --query "id" -o tsv > /dev/null
echo "✅ VPN Gateway public IPs verified successfully"

# Create Public IP for Azure Firewall
echo "🌐 Creating Public IP for Azure Firewall..."
az network public-ip create \
  --resource-group $RESOURCE_GROUP \
  --name pip-azure-firewall \
  --location $LOCATION \
  --allocation-method static \
  --sku standard

# Create Public IP for Azure Bastion
echo "🌐 Creating Public IP for Azure Bastion..."
az network public-ip create \
  --resource-group $RESOURCE_GROUP \
  --name pip-azure-bastion \
  --location $LOCATION \
  --allocation-method static \
  --sku standard

# Create Public IPs for OnPrem VPN Gateway (Active/Active)
echo "🌐 Creating Public IPs for OnPrem VPN Gateway (Active/Active)..."
az network public-ip create \
  --resource-group $RESOURCE_GROUP \
  --name pip-vng-onprem01-1 \
  --location $LOCATION \
  --allocation-method static \
  --sku standard

az network public-ip create \
  --resource-group $RESOURCE_GROUP \
  --name pip-vng-onprem01-2 \
  --location $LOCATION \
  --allocation-method static \
  --sku standard

# Wait for OnPrem public IPs to be fully ready
echo "⏳ Waiting for OnPrem public IPs to be fully provisioned..."
sleep 30

# Verify OnPrem public IPs were created successfully
echo "🔍 Verifying OnPrem VPN Gateway public IPs were created..."
az network public-ip show --resource-group $RESOURCE_GROUP --name pip-vng-onprem01-1 --query "id" -o tsv > /dev/null
az network public-ip show --resource-group $RESOURCE_GROUP --name pip-vng-onprem01-2 --query "id" -o tsv > /dev/null
echo "✅ OnPrem VPN Gateway public IPs verified successfully"

# Create VPN Gateway (this takes 20-30 minutes)
echo "🔒 Creating VPN Gateway Active/Active (this may take 20-30 minutes)..."

# Get the full resource IDs for the public IPs
HUB_PIP1_ID=$(az network public-ip show --resource-group $RESOURCE_GROUP --name pip-vng-hub01-1 --query "id" --output tsv)
HUB_PIP2_ID=$(az network public-ip show --resource-group $RESOURCE_GROUP --name pip-vng-hub01-2 --query "id" --output tsv)

az network vnet-gateway create \
  --resource-group $RESOURCE_GROUP \
  --name vng-hub01 \
  --location $LOCATION \
  --vnet $HUB_VNET \
  --public-ip-addresses $HUB_PIP1_ID $HUB_PIP2_ID \
  --gateway-type Vpn \
  --sku VpnGw1 \
  --vpn-type RouteBased \
  --asn 65509 \
  --no-wait

# Create OnPrem VPN Gateway (this takes 20-30 minutes)
echo "🏢 Creating OnPrem VPN Gateway Active/Active (this may take 20-30 minutes)..."

# Get the full resource IDs for the OnPrem public IPs
ONPREM_PIP1_ID=$(az network public-ip show --resource-group $RESOURCE_GROUP --name pip-vng-onprem01-1 --query "id" --output tsv)
ONPREM_PIP2_ID=$(az network public-ip show --resource-group $RESOURCE_GROUP --name pip-vng-onprem01-2 --query "id" --output tsv)

az network vnet-gateway create \
  --resource-group $RESOURCE_GROUP \
  --name vng-onprem01 \
  --location $LOCATION \
  --vnet $ONPREM_VNET \
  --public-ip-addresses $ONPREM_PIP1_ID $ONPREM_PIP2_ID \
  --gateway-type Vpn \
  --sku VpnGw1 \
  --vpn-type RouteBased \
  --asn 65510 \
  --no-wait

# Create Azure Firewall Policy
echo "🛡️ Creating Azure Firewall Policy..."
az network firewall policy create \
  --resource-group $RESOURCE_GROUP \
  --name fw-policy-hub01 \
  --location $LOCATION \
  --sku Premium

# Create rule collection group for firewall policy
echo "📋 Creating Firewall Rule Collection Group..."
az network firewall policy rule-collection-group create \
  --resource-group $RESOURCE_GROUP \
  --policy-name fw-policy-hub01 \
  --name DefaultRuleCollectionGroup \
  --priority 200

# Create network rule collection to allow all traffic
echo "🚦 Creating 'Allow All Traffic' firewall rule..."
az network firewall policy rule-collection-group collection add-filter-collection \
  --resource-group $RESOURCE_GROUP \
  --policy-name fw-policy-hub01 \
  --rule-collection-group-name DefaultRuleCollectionGroup \
  --name AllowAllTraffic \
  --collection-priority 100 \
  --action Allow \
  --rule-name AllowAll \
  --rule-type NetworkRule \
  --description "Allow all traffic for testing/lab purposes" \
  --destination-addresses "*" \
  --destination-ports "*" \
  --source-addresses "10.0.0.0/16" "192.168.0.0/24" \
  --ip-protocols "Any"

# Create Azure Firewall Premium
echo "🔥 Creating Azure Firewall Premium..."
az network firewall create \
  --resource-group $RESOURCE_GROUP \
  --name fw-hub01 \
  --location $LOCATION \
  --sku AZFW_VNet \
  --tier Premium

# Configure Firewall IP Configuration (separate step for reliability)
echo "🔌 Configuring Azure Firewall IP Configuration..."
az network firewall ip-config create \
  --firewall-name fw-hub01 \
  --name FW-config \
  --public-ip-address pip-azure-firewall \
  --resource-group $RESOURCE_GROUP \
  --vnet-name $HUB_VNET

# Get the firewall policy resource ID
echo "🛡️ Associating Firewall Policy..."
FIREWALL_POLICY_ID=$(az network firewall policy show \
  --resource-group $RESOURCE_GROUP \
  --name fw-policy-hub01 \
  --query "id" \
  --output tsv)

# Associate the firewall policy using the full resource ID
az network firewall update \
  --resource-group $RESOURCE_GROUP \
  --name fw-hub01 \
  --firewall-policy $FIREWALL_POLICY_ID

# Create Azure Bastion
echo "🏰 Creating Azure Bastion..."
az network bastion create \
  --resource-group $RESOURCE_GROUP \
  --name bastion-hub01 \
  --location $LOCATION \
  --vnet-name $HUB_VNET \
  --public-ip-address pip-azure-bastion \
  --sku Standard

# Create Network Security Groups (only for Spokes initially)
echo "🛡️ Creating Network Security Groups for Spokes..."
az network nsg create \
  --resource-group $RESOURCE_GROUP \
  --name nsg-spoke01 \
  --location $LOCATION

az network nsg create \
  --resource-group $RESOURCE_GROUP \
  --name nsg-spoke02 \
  --location $LOCATION

# Create NSG Rules for SSH access (Spokes only)
echo "🔑 Creating NSG Rules for SSH access (Spokes)..."
az network nsg rule create \
  --resource-group $RESOURCE_GROUP \
  --nsg-name nsg-spoke01 \
  --name Allow-SSH \
  --priority 1000 \
  --source-address-prefixes '*' \
  --destination-port-ranges 22 \
  --access Allow \
  --protocol Tcp

az network nsg rule create \
  --resource-group $RESOURCE_GROUP \
  --nsg-name nsg-spoke02 \
  --name Allow-SSH \
  --priority 1000 \
  --source-address-prefixes '*' \
  --destination-port-ranges 22 \
  --access Allow \
  --protocol Tcp

# Associate NSGs with spoke subnets only
echo "🔗 Associating NSGs with spoke subnets..."
az network vnet subnet update \
  --resource-group $RESOURCE_GROUP \
  --vnet-name $SPOKE01_VNET \
  --name default \
  --network-security-group nsg-spoke01

az network vnet subnet update \
  --resource-group $RESOURCE_GROUP \
  --vnet-name $SPOKE02_VNET \
  --name default \
  --network-security-group nsg-spoke02

# Create NICs for Spoke VMs only (OnPrem VM will be created after VPN gateway completes)
echo "🔌 Creating Network Interfaces for Spoke VMs..."
az network nic create \
  --resource-group $RESOURCE_GROUP \
  --name nic-vm-spk01-01 \
  --location $LOCATION \
  --vnet-name $SPOKE01_VNET \
  --subnet default \
  --network-security-group nsg-spoke01

az network nic create \
  --resource-group $RESOURCE_GROUP \
  --name nic-vm-spk02-01 \
  --location $LOCATION \
  --vnet-name $SPOKE02_VNET \
  --subnet default \
  --network-security-group nsg-spoke02

# Create Spoke Virtual Machines only
echo "💻 Creating Virtual Machine in Spoke01..."
az vm create \
  --resource-group $RESOURCE_GROUP \
  --name vm-spk01-01 \
  --location $LOCATION \
  --nics nic-vm-spk01-01 \
  --image Ubuntu2204 \
  --size Standard_B1s \
  --admin-username $ADMIN_USERNAME \
  --admin-password $ADMIN_PASSWORD

echo "💻 Creating Virtual Machine in Spoke02..."
az vm create \
  --resource-group $RESOURCE_GROUP \
  --name vm-spk02-01 \
  --location $LOCATION \
  --nics nic-vm-spk02-01 \
  --image Ubuntu2204 \
  --size Standard_B1s \
  --admin-username $ADMIN_USERNAME \
  --admin-password $ADMIN_PASSWORD

echo "✅ Main deployment completed successfully!"
echo ""
echo "⏳ Waiting for VPN Gateways to complete deployment..."
echo "   This may take up to 30 minutes. You can continue with other tasks."
echo "   To check status:"
echo "   - Hub: az network vnet-gateway show -g $RESOURCE_GROUP -n vng-hub01 --query provisioningState"
echo "   - OnPrem: az network vnet-gateway show -g $RESOURCE_GROUP -n vng-onprem01 --query provisioningState"
echo ""

# Wait for Hub VPN Gateway to be ready
az network vnet-gateway wait \
  --resource-group $RESOURCE_GROUP \
  --name vng-hub01 \
  --created

echo "✅ Hub VPN Gateway deployment completed!"

# Wait for OnPrem VPN Gateway to be ready  
az network vnet-gateway wait \
  --resource-group $RESOURCE_GROUP \
  --name vng-onprem01 \
  --created

echo "✅ OnPrem VPN Gateway deployment completed!"

# VPN Gateways are now ready with BGP pre-configured
echo "✅ Both VPN Gateways deployed with BGP enabled (Hub: ASN 65509, OnPrem: ASN 65510)"

# Get public IP addresses for local network gateway configuration
echo "🔍 Getting VPN Gateway public IP addresses..."
HUB_PIP1=$(az network public-ip show --resource-group $RESOURCE_GROUP --name pip-vng-hub01-1 --query "ipAddress" --output tsv)
HUB_PIP2=$(az network public-ip show --resource-group $RESOURCE_GROUP --name pip-vng-hub01-2 --query "ipAddress" --output tsv)
ONPREM_PIP1=$(az network public-ip show --resource-group $RESOURCE_GROUP --name pip-vng-onprem01-1 --query "ipAddress" --output tsv)
ONPREM_PIP2=$(az network public-ip show --resource-group $RESOURCE_GROUP --name pip-vng-onprem01-2 --query "ipAddress" --output tsv)

echo "   Hub Gateway IPs: $HUB_PIP1, $HUB_PIP2"
echo "   OnPrem Gateway IPs: $ONPREM_PIP1, $ONPREM_PIP2"

# Get BGP peering addresses from the VPN gateways and split them properly
echo "🔍 Getting BGP peering addresses from VPN gateways..."
HUB_BGP_ADDRESSES=$(az network vnet-gateway show \
  --resource-group $RESOURCE_GROUP \
  --name vng-hub01 \
  --query "bgpSettings.bgpPeeringAddress" \
  --output tsv)

ONPREM_BGP_ADDRESSES=$(az network vnet-gateway show \
  --resource-group $RESOURCE_GROUP \
  --name vng-onprem01 \
  --query "bgpSettings.bgpPeeringAddress" \
  --output tsv)

echo "   Hub BGP Addresses (raw): $HUB_BGP_ADDRESSES"
echo "   OnPrem BGP Addresses (raw): $ONPREM_BGP_ADDRESSES"

# Split BGP addresses for Active/Active setup
HUB_BGP_ADDRESS1=$(echo $HUB_BGP_ADDRESSES | cut -d',' -f1)
HUB_BGP_ADDRESS2=$(echo $HUB_BGP_ADDRESSES | cut -d',' -f2)
ONPREM_BGP_ADDRESS1=$(echo $ONPREM_BGP_ADDRESSES | cut -d',' -f1)
ONPREM_BGP_ADDRESS2=$(echo $ONPREM_BGP_ADDRESSES | cut -d',' -f2)

echo "   Hub Instance 1 BGP: $HUB_BGP_ADDRESS1"
echo "   Hub Instance 2 BGP: $HUB_BGP_ADDRESS2"
echo "   OnPrem Instance 1 BGP: $ONPREM_BGP_ADDRESS1"
echo "   OnPrem Instance 2 BGP: $ONPREM_BGP_ADDRESS2"

# Create Local Network Gateways for Site-to-Site connections with BGP settings
echo "🔗 Creating Local Network Gateways with BGP settings for Site-to-Site IPSec connections..."

# Local Network Gateways representing OnPrem instances (for Hub to connect to)
az network local-gateway create \
  --resource-group $RESOURCE_GROUP \
  --name lng-onprem-instance1 \
  --location $LOCATION \
  --gateway-ip-address $ONPREM_PIP1 \
  --local-address-prefixes 192.168.0.0/24 \
  --asn 65510 \
  --bgp-peering-address $ONPREM_BGP_ADDRESS1

az network local-gateway create \
  --resource-group $RESOURCE_GROUP \
  --name lng-onprem-instance2 \
  --location $LOCATION \
  --gateway-ip-address $ONPREM_PIP2 \
  --local-address-prefixes 192.168.0.0/24 \
  --asn 65510 \
  --bgp-peering-address $ONPREM_BGP_ADDRESS2

# Local Network Gateways representing Hub instances (for OnPrem to connect to)
az network local-gateway create \
  --resource-group $RESOURCE_GROUP \
  --name lng-hub-instance1 \
  --location $LOCATION \
  --gateway-ip-address $HUB_PIP1 \
  --local-address-prefixes 10.0.0.0/16 \
  --asn 65509 \
  --bgp-peering-address $HUB_BGP_ADDRESS1

az network local-gateway create \
  --resource-group $RESOURCE_GROUP \
  --name lng-hub-instance2 \
  --location $LOCATION \
  --gateway-ip-address $HUB_PIP2 \
  --local-address-prefixes 10.0.0.0/16 \
  --asn 65509 \
  --bgp-peering-address $HUB_BGP_ADDRESS2

echo "✅ Local Network Gateways with BGP settings created successfully!"

# Create Site-to-Site IPSec connections for Active/Active setup (4 connections total)
echo "🔗 Creating Site-to-Site IPSec connections for Active/Active setup..."

# Hub connections to OnPrem instances
az network vpn-connection create \
  --resource-group $RESOURCE_GROUP \
  --name hub-to-onprem-instance1 \
  --location $LOCATION \
  --vnet-gateway1 vng-hub01 \
  --local-gateway2 lng-onprem-instance1 \
  --enable-bgp \
  --shared-key "VerySecureSharedKey123!"

az network vpn-connection create \
  --resource-group $RESOURCE_GROUP \
  --name hub-to-onprem-instance2 \
  --location $LOCATION \
  --vnet-gateway1 vng-hub01 \
  --local-gateway2 lng-onprem-instance2 \
  --enable-bgp \
  --shared-key "VerySecureSharedKey123!"

# OnPrem connections to Hub instances  
az network vpn-connection create \
  --resource-group $RESOURCE_GROUP \
  --name onprem-to-hub-instance1 \
  --location $LOCATION \
  --vnet-gateway1 vng-onprem01 \
  --local-gateway2 lng-hub-instance1 \
  --enable-bgp \
  --shared-key "VerySecureSharedKey123!"

az network vpn-connection create \
  --resource-group $RESOURCE_GROUP \
  --name onprem-to-hub-instance2 \
  --location $LOCATION \
  --vnet-gateway1 vng-onprem01 \
  --local-gateway2 lng-hub-instance2 \
  --enable-bgp \
  --shared-key "VerySecureSharedKey123!"

echo "✅ All Site-to-Site IPSec connections created successfully!"

# Now that VPN gateways are complete, create OnPrem VM resources
echo ""
echo "🏢 Creating OnPrem VM resources (now that VPN gateway is ready)..."

# Create OnPrem NSG
echo "🛡️ Creating OnPrem Network Security Group..."
az network nsg create \
  --resource-group $RESOURCE_GROUP \
  --name nsg-onprem \
  --location $LOCATION

# Create OnPrem NSG Rule
echo "🔑 Creating OnPrem NSG Rule for SSH access..."
az network nsg rule create \
  --resource-group $RESOURCE_GROUP \
  --nsg-name nsg-onprem \
  --name Allow-SSH \
  --priority 1000 \
  --source-address-prefixes '*' \
  --destination-port-ranges 22 \
  --access Allow \
  --protocol Tcp

# Associate OnPrem NSG with subnet
echo "🔗 Associating OnPrem NSG with subnet..."
az network vnet subnet update \
  --resource-group $RESOURCE_GROUP \
  --vnet-name $ONPREM_VNET \
  --name vm-subnet \
  --network-security-group nsg-onprem

# Create OnPrem VM NIC
echo "🔌 Creating OnPrem VM Network Interface..."
az network nic create \
  --resource-group $RESOURCE_GROUP \
  --name nic-vm-onprem-01 \
  --location $LOCATION \
  --vnet-name $ONPREM_VNET \
  --subnet vm-subnet \
  --network-security-group nsg-onprem

# Create OnPrem VM
echo "🏢 Creating Virtual Machine in OnPrem..."
az vm create \
  --resource-group $RESOURCE_GROUP \
  --name vm-onprem-01 \
  --location $LOCATION \
  --nics nic-vm-onprem-01 \
  --image Ubuntu2204 \
  --size Standard_B1s \
  --admin-username $ADMIN_USERNAME \
  --admin-password $ADMIN_PASSWORD

echo "✅ OnPrem VM created successfully!"

echo "✅ Firewall configured with 'Allow All Traffic' rule"

# Wait a bit more for firewall to be fully ready
echo "⏳ Allowing extra time for Azure Firewall to be fully ready..."
sleep 60

# Create Route Tables for Spokes (now that everything else is ready)
echo ""
echo "🗺️ Creating Route Tables for Spoke subnets..."
az network route-table create \
  --resource-group $RESOURCE_GROUP \
  --name rt-spoke01 \
  --location $LOCATION \
  --disable-bgp-route-propagation true

az network route-table create \
  --resource-group $RESOURCE_GROUP \
  --name rt-spoke02 \
  --location $LOCATION \
  --disable-bgp-route-propagation true

# Get Azure Firewall private IP address (should be ready by now)
echo "🔍 Getting Azure Firewall private IP address..."

# Try multiple methods with proper error handling
for attempt in {1..10}; do
  echo "   Attempt $attempt: Retrieving firewall IP..."
  
  # Method 1: ip-config list
  FIREWALL_PRIVATE_IP=$(az network firewall ip-config list \
    --firewall-name fw-hub01 \
    --resource-group $RESOURCE_GROUP \
    --query "[0].privateIpAddress" \
    --output tsv 2>/dev/null)
  
  # Method 2: firewall show (if method 1 fails)
  if [ -z "$FIREWALL_PRIVATE_IP" ] || [ "$FIREWALL_PRIVATE_IP" = "null" ]; then
    FIREWALL_PRIVATE_IP=$(az network firewall show \
      --resource-group $RESOURCE_GROUP \
      --name fw-hub01 \
      --query "ipConfigurations[0].privateIpAddress" \
      --output tsv 2>/dev/null)
  fi
  
  # Check if we got a valid IP (basic validation)
  if [[ $FIREWALL_PRIVATE_IP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "   ✅ Azure Firewall private IP: $FIREWALL_PRIVATE_IP"
    break
  else
    echo "   ⏳ IP not ready yet (got: '$FIREWALL_PRIVATE_IP'), waiting 30 seconds..."
    sleep 30
  fi
  
  if [ $attempt -eq 10 ]; then
    echo "⚠️ Error: Could not retrieve valid Azure Firewall private IP after 10 attempts"
    echo "   Please check the firewall deployment manually:"
    echo "   az network firewall show -g $RESOURCE_GROUP -n fw-hub01 --query ipConfigurations"
    exit 1
  fi
done

# Create default routes to Azure Firewall
echo "🛣️ Creating default routes to Azure Firewall..."
az network route-table route create \
  --resource-group $RESOURCE_GROUP \
  --route-table-name rt-spoke01 \
  --name default-to-firewall \
  --address-prefix 0.0.0.0/0 \
  --next-hop-type VirtualAppliance \
  --next-hop-ip-address $FIREWALL_PRIVATE_IP

az network route-table route create \
  --resource-group $RESOURCE_GROUP \
  --route-table-name rt-spoke02 \
  --name default-to-firewall \
  --address-prefix 0.0.0.0/0 \
  --next-hop-type VirtualAppliance \
  --next-hop-ip-address $FIREWALL_PRIVATE_IP

# Associate route tables with spoke subnets
echo "🔗 Associating route tables with spoke subnets..."
az network vnet subnet update \
  --resource-group $RESOURCE_GROUP \
  --vnet-name $SPOKE01_VNET \
  --name default \
  --route-table rt-spoke01

az network vnet subnet update \
  --resource-group $RESOURCE_GROUP \
  --vnet-name $SPOKE02_VNET \
  --name default \
  --route-table rt-spoke02

echo "✅ Route tables configured successfully!"

echo ""
echo "📋 Deployment Summary:"
echo "   Resource Group: $RESOURCE_GROUP"
echo "   Location: $LOCATION"
echo "   Hub VNet: $HUB_VNET ($HUB_CIDR)"
echo "   Spoke01 VNet: $SPOKE01_VNET ($SPOKE01_CIDR)"
echo "   Spoke02 VNet: $SPOKE02_VNET ($SPOKE02_CIDR)"
echo "   OnPrem VNet: $ONPREM_VNET ($ONPREM_CIDR)"
echo "   Hub VPN Gateway: vng-hub01 (VpnGw1 SKU, Active/Active, BGP ASN: 65509, IPs: pip-vng-hub01-1/2)"
echo "   OnPrem VPN Gateway: vng-onprem01 (VpnGw1 SKU, Active/Active, BGP ASN: 65510, IPs: pip-vng-onprem01-1/2)"
echo "   Site-to-Site IPSec Connections: 4 connections for full active/active mesh (BGP enabled)"
echo "   Local Network Gateways: lng-onprem-instance1/2, lng-hub-instance1/2 (with BGP settings)"
echo "   Azure Firewall: fw-hub01 (Premium SKU, Allow All Traffic rule, IP: pip-azure-firewall) - Private IP: $FIREWALL_PRIVATE_IP"
echo "   Azure Bastion: bastion-hub01 (Standard SKU, IP: pip-azure-bastion)"
echo "   Route Tables: rt-spoke01, rt-spoke02 (BGP propagation disabled)"
echo "   Default Routes: All spoke traffic routed through Azure Firewall"
echo "   VMs: vm-spk01-01, vm-spk02-01, vm-onprem-01 (private IPs only)"

echo ""
echo "🛣️ Traffic Flow:"
echo "   - Spoke VMs ↓ Azure Firewall ↓ Hub/Internet/OnPrem"
echo "   - OnPrem (192.168.0.0/24) ↭(VPN/BGP)↭ Hub (10.0.0.0/23) ↓ Spokes (10.0.2.0/24, 10.0.3.0/24)"
echo "🏰 VM Access: Use Azure Bastion (bastion-hub01) to connect to VMs securely"
echo "🔑 VM Credentials: Username: $ADMIN_USERNAME, Password: $ADMIN_PASSWORD"
echo "⚠️ IMPORTANT: Change default password immediately!"
echo ""
echo "🚦 Firewall Configuration:"
echo "   ✅ 'Allow All Traffic' rule configured for testing/lab purposes"
echo "   ⚠️ For production: Replace with specific security rules"
echo "   🔍 Current rule allows all traffic from 10.0.0.0/16 to anywhere"
echo ""
echo "🔗 VPN/BGP Configuration:"
echo "   ✅ Site-to-Site VPN established between Hub and OnPrem"
echo "   ✅ BGP enabled for dynamic routing"
echo "   - Hub VPN ASN: 65509"
echo "   - OnPrem VPN ASN: 65510"
echo "   - Shared Key: VerySecureSharedKey123!"
echo "   ✅ Active/Active configuration for high availability"
echo ""
echo "🔍 Post-deployment checklist:"
echo "   ✅ Infrastructure deployed"
echo "   ✅ Firewall configured with permissive rules (ready for testing)"
echo "   ✅ Site-to-Site VPN with BGP established"
echo "   ⚠️ Change VM passwords"
echo "   ◦ Access VMs via Azure Bastion (no public IPs needed)"
echo "   ◦ Test connectivity: Hub ↔ OnPrem ↔ Spokes"
echo "   ◦ Monitor BGP routes and VPN status"
echo "   ◦ Set up monitoring and logging"
echo "   ◦ Replace permissive firewall rules with specific security rules for production"
echo ""
echo "🧪 Testing Connectivity:"
echo "   - Check VPN status: az network vpn-connection show -g $RESOURCE_GROUP -n hub-to-onprem-instance1"
echo "   - Check all connections: az network vpn-connection list -g $RESOURCE_GROUP --output table"
echo "   - View BGP routes: az network vnet-gateway list-bgp-peer-status -g $RESOURCE_GROUP -n vng-hub01"
echo "   - View OnPrem BGP routes: az network vnet-gateway list-bgp-peer-status -g $RESOURCE_GROUP -n vng-onprem01"
echo "   - Test ping from vm-onprem-01 (192.168.0.x) to spoke VMs (10.0.2.x, 10.0.3.x)"
echo "   - Test ping between Hub (10.0.x.x) and OnPrem (192.168.0.x) networks"
echo ""
echo "⚠️ Security Note: The firewall is configured with 'Allow All' rules for testing."
echo "   For production deployments, replace with specific security rules!"
echo ""

# Calculate and display total deployment time
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
HOURS=$((DURATION / 3600))
MINUTES=$(((DURATION % 3600) / 60))
SECONDS=$((DURATION % 60))

echo "⏰ Deployment completed at: $(date)"
if [ $HOURS -gt 0 ]; then
    echo "⏱️ Total deployment time: ${HOURS}h ${MINUTES}m ${SECONDS}s"
elif [ $MINUTES -gt 0 ]; then
    echo "⏱️ Total deployment time: ${MINUTES}m ${SECONDS}s"
else
    echo "⏱️ Total deployment time: ${SECONDS}s"
fi
echo ""

echo "🎉 Complete Hub-Spoke Network with OnPrem VPN and BGP deployment finished!"