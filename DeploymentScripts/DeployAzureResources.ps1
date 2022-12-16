#Implementation Reference in README

#Variable Declaration Section
$subscriptionName = "Visual Studio Enterprise Subscription"
$resourcegroupName = "rg-zerotrust-appgw-tls"
$deploymentLocation = "West US"
$hostName ="www.contoso.com"
# Connect to an Azure Account
Connect-AzAccount

#Select the subscription to use for this scenario.
Select-Azsubscription -SubscriptionName $subscriptionName
#Create a resource group. (Skip this step if you're using an existing resource group.)
New-AzResourceGroup -Name $resourcegroupName -Location $deploymentLocation

# Creating the Virtual Network Resources
#Assign an address range for the subnet to be used for the application gateway.
$gwSubnet = New-AzVirtualNetworkSubnetConfig -Name 'appgwsubnet' -AddressPrefix 10.0.0.0/24
#Assign an address range to be used for the backend address pool.
$nicSubnet = New-AzVirtualNetworkSubnetConfig  -Name 'appsubnet' -AddressPrefix 10.0.2.0/24
#Create a virtual network with the subnets defined in the preceding steps.
$vnet = New-AzvirtualNetwork -Name 'appgwvnet' `
-ResourceGroupName $resourcegroupName -Location $deploymentLocation `
 -AddressPrefix 10.0.0.0/16 -Subnet $gwSubnet, $nicSubnet

#Retrieve the virtual network resource and subnet resources to be used in the steps that follow.
$vnet = Get-AzvirtualNetwork -Name 'appgwvnet' -ResourceGroupName $resourcegroupName
$gwSubnet = Get-AzVirtualNetworkSubnetConfig -Name 'appgwsubnet' -VirtualNetwork $vnet
$nicSubnet = Get-AzVirtualNetworkSubnetConfig -Name 'appsubnet' -VirtualNetwork $vnet

#Create a public IP resource to be used for the application gateway.
$publicip = New-AzPublicIpAddress -ResourceGroupName $resourcegroupName -Name 'publicIP01' `-Location $deploymentLocation -AllocationMethod Dynamic

#Create an application gateway IP configuration.
$gipconfig = New-AzApplicationGatewayIPConfiguration -Name 'gwconfig' -Subnet $gwSubnet

#Create a frontend IP configuration
$fipconfig = New-AzApplicationGatewayFrontendIPConfig -Name 'fip01' -PublicIPAddress $publicip

#Configure the backend IP address pool with the IP addresses of the backend web servers
## Note
## A fully qualified domain name (FQDN) is also a valid value to use in place of an IP address for the backend servers. 
## You enable it by using the -BackendFqdns switch. Howver when using a FQDN, the appgw should be able to resolve the FQDN to a private/public IP address 
$pool = New-AzApplicationGatewayBackendAddressPool -Name 'pool01' -BackendIPAddresses 10.0.2.4

#Configure the frontend IP port for the public IP endpoint. This port is the port that end users connect to.
$fp = New-AzApplicationGatewayFrontendPort -Name 'port01'  -Port 443

#Configure the certificate for the application gateway. This certificate is used to decrypt and reencrypt the traffic on the application gateway.
$passwd = ConvertTo-SecureString  "appgwtlssecret#12" -AsPlainText -Force 
$cert = New-AzApplicationGatewaySSLCertificate -Name appgwcert `
-CertificateFile "C:\DevApplications\ZeroTrust-Networking-E2E-Tls-AppGateway\appgw.pfx" `
-Password $passwd

#Create the HTTP listener for the application gateway. Assign the frontend IP configuration, port, and TLS/SSL certificate to use.
$listener = New-AzApplicationGatewayHttpListener `
-Name listener01 -Protocol Https `
-FrontendIPConfiguration $fipconfig `
-FrontendPort $fp -SSLCertificate $cert

#For Application Gateway v2 SKU, create a trusted root certificate
$trustedRootCert01 = New-AzApplicationGatewayTrustedRootCertificate `
-Name "CustomCARoot" -CertificateFile  "C:\DevApplications\ZeroTrust-Networking-E2E-Tls-AppGateway\customrootCA.cer"

#Create the health probe
$probe=New-AzApplicationGatewayProbeConfig `
  -Name httpsbackendporbe `
  -Protocol Https `
  -HostName $hostName `
  -Path "/" `
  -Interval 15 `
  -Timeout 20 `
  -UnhealthyThreshold 3

#Configure the HTTP settings for the application gateway back end. Assign the certificate uploaded in the preceding step to the HTTP settings.
$poolSetting01 = New-AzApplicationGatewayBackendHttpSettings `
-Name “setting01” -Port 443 -Protocol Https `
-CookieBasedAffinity Disabled -TrustedRootCertificate $trustedRootCert01 `
-HostName $hostName `
-Probe $probe

#Create a load-balancer routing rule that configures the load balancer behavior. In this example, a basic round-robin rule is created.
$rule = New-AzApplicationGatewayRequestRoutingRule -Name 'routehttpstraffic' `
-RuleType basic -BackendHttpSettings $poolSetting `
-HttpListener $listener -BackendAddressPool $pool

#Configure the instance size of the application gateway
$sku = New-AzApplicationGatewaySku -Name Standard_v2 -Tier Standard_v2 -Capacity 2

#Configure the TLS policy to be used on the application gateway
$SSLPolicy = New-AzApplicationGatewaySSLPolicy -MinProtocolVersion TLSv1_2 `
-CipherSuite "TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256", "TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384", "TLS_RSA_WITH_AES_128_GCM_SHA256" `
-PolicyType Custom

#Create the application Gateway
$appgw = New-AzApplicationGateway -Name appgateway `
-SSLCertificates $cert `
-ResourceGroupName $resourcegroupName `
-Location $deploymentLocation `
-BackendAddressPools $pool `
-BackendHttpSettingsCollection $poolSetting01 `
-FrontendIpConfigurations $fipconfig `
-GatewayIpConfigurations $gipconfig `
-FrontendPorts $fp `
-HttpListeners $listener `
-RequestRoutingRules $rule `
-Sku $sku `
-SSLPolicy $SSLPolicy `
-TrustedRootCertificate $trustedRootCert01 -Verbose