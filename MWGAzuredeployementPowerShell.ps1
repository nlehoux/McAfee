<#
.Synopsis
McAfeeWebGateway deployement in Azure script
.Description
This will help with the deployement of McAfee Web Gateway in Azure IaaS. This is meant to help the deployement in a PoC.
.Parameter ResourceGroupName
This is the Name of the Ressource Groupe that will hold the McAfee Web Gateway in your Azure IaaS
ex: mwgnativegroup
.Parameter location
In Which Azure IaaS data center this should be located
ex:eastus
.Parameter StorageAcountName
This is the Name of your Storage Account used for hosting the page blob for the McAfee Web Gateway image.
ex:acmemwgimgstorage
.Parameter PathofLocalVHDtoExport
This is the path of the VHD imaged provided by mcafee 
ex:'C:\Users\sysadmin.NICOLAB\Documents\McAfee\Web\mwg-8.2.0-29996.vhd'
.Parameter NameofVHDinBlob
This is the name of the VHD file in the container
ex: mwg-8.2.0-29996.vhd
.Parameter StorageContainerName
This is the container's name in the your Page-Blob
ex:mwgimg
.Parameter StorageSKU
What sku do you want for your Blob? 
The choice are: "Standard_LRS" , "Standard_ZRS" , "Standard_GRS" , "Standard_RAGRS" , "Premium_LRS" , "Premium_ZRS" , "Standard_GZRS" , "Standard_RAGZRS"
.Parameter OSDiskName
This is the name of the McAfee Web Gateway disk used for the VM
ex:mwgmanagedimg
.Parameter VMDiskSize
This is the size in GB alocated for the disk of the VM
ex:64
.Parameter VMDiskSKU
What SKU do you want for the disk of the McAfee Web Gateway's VM?
The choice are: "Standard_LRS" , "Standard_ZRS" , "Standard_GRS" , "Standard_RAGRS" , "Premium_LRS" , "Premium_ZRS" , "Standard_GZRS" , "Standard_RAGZRS"
.Parameter VMDiskLocation
Where do you want the disk of the McAfee Web Gateway's VM located?
ex:eastus
.Parameter NetworkName
This is the name of your network where the McAfee Web Gateway's VM will be located
ex:AZNet
.Parameter DNSNameLabel
The name of your DNS label
ex:azdnsname
.Parameter NICName
This is the NIC of the McAfee Web Gateway's VM
ex:MWGNIC
.Parameter PublicIPAddressName
This is the Name you give to the Public IP to access the McAfee Web Gateway's VM
ex:AZPIP
.Parameter SubnetName
This is the name of the subnet where the McAfee Web Gateway's VM is located
ex:AZSubnet
.Parameter VnetAddressPrefix
Network in CIDR format
ex:172.16.0.0/16
.Parameter SubnetAddressPrefix
Network address
ex:172.16.78.0/24
.Parameter VMName
This is the name of the virtual appliance McAfee Web Gateway
ex:MWGappl1
.Parameter VMSize
This is the size of the vm. This will depend on the location you choosen. Run the Get-AzVMSize to see the choice available to you.
ex:Standard_D4_v3
.Link
https://docs.mcafee.com/bundle/web-gateway-8.2.x-installation-guide/page/GUID-4E6994DC-47A6-4BD8-BE0E-6177FC76C008.html
https://docs.microsoft.com/en-us/azure/virtual-machines/windows/sizes
#>
Param (
    #$mwgcredential = Get-Credential -UserName azure-user -Message 'azure-user for ssh access'
    [Parameter (Mandatory=$true)]
    [System.String]$ResourceGroupName,          # = 'mwgnativegroup'
    [Parameter (Mandatory=$true)]
    [System.String]$location,                   # = 'eastus'
    [Parameter (Mandatory=$true)]
    [System.String]$StorageAcountName,          # = 'azmwgimgstorage'
    [Parameter (Mandatory=$true,
    HelpMessage="The path where the VHD image is located")]
    [System.String]$PathofLocalVHDtoExport,     # = 'C:\Users\sysadmin.NICOLAB\Documents\McAfee\Web\mwg-8.2.0-29996.vhd'
    [Parameter (Mandatory=$true)]
    [System.String]$NameofVHDinBlob,            # = 'mwg-8.2.0-29996.vhd'
    [Parameter (Mandatory=$true)]
    [System.String]$StorageContainerName,       # = 'mwgimg'
    [Parameter (Mandatory=$true)]
    [ValidateSet("Standard_LRS" , "Standard_ZRS" , "Standard_GRS" , "Standard_RAGRS" , "Premium_LRS" , "Premium_ZRS" , "Standard_GZRS" , "Standard_RAGZRS")]
    [String]$StorageSKU,                        # = 'Standard_LRS'
    [Parameter (Mandatory=$true)]
    [System.String]$OSDiskName,                 # = 'mwgmanagedimg'
    [Parameter (Mandatory=$true)]
    [System.Int32]$VMDiskSize,                  # = '64'
    [ValidateSet("Standard_LRS" , "Standard_ZRS" , "Standard_GRS" , "Standard_RAGRS" , "Premium_LRS" , "Premium_ZRS" , "Standard_GZRS" , "Standard_RAGZRS")]
    [Parameter (Mandatory=$true)]
    [System.String]$VMDiskSKU,                  # = 'Standard_LRS'
    [Parameter (Mandatory=$true)]
    [System.String]$VMDiskLocation,             # = 'eastus'

    [Parameter (Mandatory=$true)]
    [System.String]$NetworkName,                # = "AZNet"    
    [Parameter (Mandatory=$true)]
    [System.String]$DNSNameLabel,               # = "azdnsname"
    [Parameter (Mandatory=$true)]
    [System.String]$NICName,                    # = "MWGNIC"
    [Parameter (Mandatory=$true)]
    [System.String]$PublicIPAddressName,        # = "AZPIP"
    [Parameter (Mandatory=$true)]
    [System.String]$SubnetName,                 # = "AZSubnet"
    [Parameter (Mandatory=$true)]
    [System.String]$VnetAddressPrefix,        # = "172.16.0.0/16"
    [Parameter (Mandatory=$true)]
    [System.String]$SubnetAddressPrefix,       # = "172.16.78.0/24"
    [Parameter (Mandatory=$true)]
    [System.String]$VMName,                     # = "MWGappl1"
    [Parameter (Mandatory=$true)]
    [System.String]$VMSize                     # = "Standard_D4_v3"
    )
echo "Logon to your azure account"
Connect-AzAccount

echo "Create resource group $ResourceGroupName in $location"
New-AzResourceGroup `
	-name $ResourceGroupName `
	-location $location

echo "Create a Storage with storage account name:  $StorageAcountName in the resource group: $ResourceGroupName in $location. The SKU used is: $StorageSKU" 
New-AzStorageAccount `
	-ResourceGroupName $ResourceGroupName `
	-location $location `
	-name $StorageAcountName `
	-kind Storage `
	-SkuName $StorageSKU

echo "The storage container $StorageContainerName is built in the $StorageAcountName from your resource group $ResourceGroupName"
New-AzRmStorageContainer `
	-ResourceGroupName $ResourceGroupName `
	-StorageAccountName $StorageAcountName `
	-name $StorageContainerName

echo "Copying $PathofLocalVHDtoExport
into your blob container $Container.
Its name in the container will be $NameofVHDinBlob"
$StorageAccount = Get-AzureRmStorageAccount | where {$_.StorageAccountName -eq $StorageAcountName}

$Container = $StorageAccount | Get-AzureStorageContainer

#the Blob needs to be a Page Blob not a block Blob which is the default option
$Container | Set-AzureStorageBlobContent `
			-BlobType Page `
			-File $PathofLocalVHDtoExport `
            -Blob $NameofVHDinBlob


echo "Creating the managed disk"


$storageAccountId = (Get-AzStorageAccount | where {$_.StorageAccountName -eq $StorageAcountName} | select id).id
$StorageKey = (Get-AzStorageAccountKey -StorageAccountName $StorageAcountName -ResourceGroupName $ResourceGroupName | where {$_.KeyName -eq 'key1'}).Value
$StorageContext = New-AzStorageContext -StorageAccountName $StorageAcountName -StorageAccountKey $StorageKey
$SourceImageUri = (Get-AzStorageBlob -Container "mwgimg" -Blob 'mwg*'-Context $StorageContext).ICloudBlob.Uri.AbsoluteUri


$diskConfig = New-AzDiskConfig `
			-DiskSizeGB $VMDiskSize `
			-SKU $VMDiskSKU `
			-Location $location `
			-CreateOption Import `
			-OsType Linux `
			-StorageAccountId $storageAccountId `
			-SourceUri $SourceImageUri

New-AzDisk `
	-Disk $diskConfig `
	-ResourceGroupName $ResourceGroupName `
	-DiskName $OSDiskName 

$mwgDiskID = (Get-AzDisk -ResourceGroupName $ResourceGroupName -DiskName $OSDiskName).Id
$ManagedDiskID = (Get-AzDisk | select id).id

echo "The managed disk $ManagedDiskID has been created 
it has a size of $VMDiskSize GB, 
its SKU is $VMDiskSKU,
it is located in $location
This is an import
from a Linux image
it will be located in  $SourceImageUri"


echo "Creating Network Security Rules to be able to access the McAfee Web Gateway 
GUI via https on port 4712
the proxy will accept traffic from port 9090
and you can access the McAfee Web Gatway via port 22"
$mwgui = New-AzNetworkSecurityRuleConfig `
    -Name "MWGUiHTTPS" `
    -Description "Allow HTTPS to MWG Interface from internet" `
    -Access "Allow" `
    -Protocol "Tcp" `
    -Direction "Inbound" `
    -Priority "102" `
    -SourceAddressPrefix "Internet" `
    -SourcePortRange * `
    -DestinationAddressPrefix * `
    -DestinationPortRange 4712

$proxyport = New-AzNetworkSecurityRuleConfig `
    -Name "ProxyPort" `
    -Description "Allow Communication to Proxy from internet" `
    -Access "Allow" `
    -Protocol "Tcp" `
    -Direction "Inbound" `
    -Priority "101" `
    -SourceAddressPrefix "Internet" `
    -SourcePortRange * `
    -DestinationAddressPrefix * `
    -DestinationPortRange 9090

$ssh = New-AzNetworkSecurityRuleConfig `
    -Name "SSH" `
    -Description "Allow SSH Communication to Proxy from internet" `
    -Access "Allow" `
    -Protocol "Tcp" `
    -Direction "Inbound" `
    -Priority "100" `
    -SourceAddressPrefix "Internet" `
    -SourcePortRange * `
    -DestinationAddressPrefix * `
    -DestinationPortRange 22

$mwgnsg = New-AzNetworkSecurityGroup `
    -ResourceGroupName $ResourceGroupName `
    -Location $location `
    -Name "MWGNetworkSecurityGroup" `
    -SecurityRules $mwgui,$proxyport,$ssh

$NSGID = (Get-AzNetworkSecurityGroup).id

echo "done"

echo "Creating the Network $NetworkName"

$SingleSubnet = New-AzVirtualNetworkSubnetConfig `
			-Name $SubnetName `
			-AddressPrefix $SubnetAddressPrefix


$Vnet = New-AzVirtualNetwork `
		-Name $NetworkName `
		-ResourceGroupName $ResourceGroupName `
		-Location $location `
		-AddressPrefix $VnetAddressPrefix `
		-Subnet $SingleSubnet

$PIP = New-AzPublicIpAddress `
		-Name $PublicIPAddressName `
		-DomainNameLabel $DNSNameLabel `
		-ResourceGroupName $ResourceGroupName `
		-Location $location `
		-AllocationMethod Dynamic

$NIC = New-AzNetworkInterface `
		-Name $NICName `
		-ResourceGroupName $ResourceGroupName `
		-Location $location `
		-SubnetId $Vnet.Subnets[0].Id `
		-PublicIpAddressId $PIP.Id `
		-NetworkSecurityGroupId $NSGID

echo "$NetworkName has been created in the resource group $ResourceGroupName which is in $location
the subnet is $SingleSubnet
the NIC $NIC has been created too"


echo " Creating the VM $VMName with the size $VMSize."

$VirtualMachine = New-AzVMConfig `
			-VMName $VMName `
			-VMSize $VMSize



$VirtualMachine = `
	Add-AzVMNetworkInterface `
		-VM $VirtualMachine `
		-Id $NIC.Id

$VirtualMachine = `
    Set-AzVMOSDisk `
        -VM $VirtualMachine `
        -CreateOption attach `
        -Linux `
        -ManagedDiskId $ManagedDiskID

New-AzVM `
	-ResourceGroupName $ResourceGroupName `
	-Location $location `
	-VM $VirtualMachine `
	-Verbose
