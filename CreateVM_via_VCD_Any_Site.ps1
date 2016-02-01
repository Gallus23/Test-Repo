<#
  This is a script that can be used to provision a vApp/VM from a template, 
  connect the VM to the network and get an IP, power on the VM, check that status,
  and then delete the vApp/VM.
  
  Note: This script assumes there is a single VM in template.  If you want to utilize
        vApps with multiple VM's contained in it, you will need to modify the script
		to utilize foreach () constructs to connect with VM to the vApp network and get
		an IP address.
  
  Usage: ProvisionVm.pas -vcddns icd-mystack.pearson.com 
						-org "johnlamb-egw-demo" 
						-orgnet <BE | FE> 
						-catalog "*public-catalog" 
						-template "Windows Server 2008 R2 - Standard"
						-vappname "test vapp"
						-delay 60
						-user john.lamb@pearson.com 
						[-pwd sometext]
#>
[CmdletBinding()]
Param(
  [Parameter(Mandatory=$True)]
       [string]$vcddns,

  [Parameter(Mandatory=$True)]
       [string]$org,  

  [Parameter(Mandatory=$True)]
       [string]$orgnet, 
	   
  [Parameter(Mandatory=$True)]
       [string]$catalog, 

  [Parameter(Mandatory=$True)]
       [string]$template, 

  [Parameter(Mandatory=$True)]
       [string]$vappname, 
	   
  [Parameter(Mandatory=$True)]
       [string]$delay,	
	   
  [Parameter(Mandatory=$True)]
       [string]$user,

  [Parameter(Mandatory=$True)]
       [string]$pwd
  )
<# Load the Snapins for VMware #>
$snapins = @("VMware.VimAutomation.Core", "VMware.VimAutomation.Cloud")
foreach ($snapin in $snapins){
  try {
  Write-Host "Trying to load snapin $snapin"
  Add-PSSnapin $snapin -ErrorAction Stop
  Write-Host "$Snapin loaded"
  }
  catch {
  Write-Host "$snapin was already loaded or cannot be loaded"
  }
}

  
<# connect to the vCD Cell server #>
If ($pwd) {  
	connect-ciserver -server $vcddns -org $org -user $user -password $pwd
} else {
    <# prompt user interactively for password #>
	connect-ciserver -server $vcddns -org $org -user 
}

<#script assumes a single vDC, if this changes, you will need to pass inthe vDC to utilize as an org and add a where-object clause #>
$myorgvdc = get-orgvdc

<# debug code
    echo $("my vdc storage use: " + $myorgvdc.storageusedgb)
	$myvms = get-civm
	$myvms
	$myvapps = get-civapp
	$myvapps
#>

<#get the catalogs the user has access to#> 
echo $("Getting the catalogs available to the user logged in...")
$mycatalogs = get-catalog

<#get the templates from the catalog specified by the user#>
echo $("Getting the templates from the specified catalog...")
$catalogtemplates = $mycatalogs | where-object {$_.name -like $catalog} | get-civapptemplate

<#get the template specified by the user#>
echo $("Getting the template information specified if matched...")
$deploytemplate = $catalogtemplates | where-object {$_.name -eq $template }

<#get the BE and FE networks within the Org #>
echo $("Getting the Org Networks for BE and FE...")
$myBEnetwork = get-orgnetwork | where-object {$_.name -like "BE*"}
$myFEnetwork = get-orgnetwork | where-object {$_.name -like "FE*"}

<#provision the specified template in the org as a new vApp withe specified user name #>
echo $("Deploying the vApp from the template: $template")
$myNewvAPP = new-civapp -name $vappName -description "Created by Powershell script." -OrgVdc $myorgvdc -vapptemplate $deploytemplate

<#get the network to use for the vAPP as specified by the user param orgnet and add the network specified to the vApp#>
echo $("Creating the specified network in the vApp...")
if ($orgnet -eq "BE") {
	$myNewvAppNetwork = new-civappnetwork -direct -ParentOrgNetwork $myBEnetwork -vApp $myNewvAPP
} else {
	$myNewvAppNetwork = new-civappnetwork -direct -ParentOrgNetwork $myFEnetwork -vApp $myNewvAPP
}

<#get the VM in the newly deloyed vApp - assuming a single VM but this could return multiples #>
echo $("Getting the VM details as deployed in the new vApp...")
$mynewVM = $myNewvApp | Get-CIVM  

<#here is where you would need to consider mulitple VM's per vApp and do a foreach () #>
	<#get the primary NIC of the VM #>
	echo $("   Getting the Primary NIC for the VM...")
	$myNewVMNIC = ($myNewVM | where-object {$_.vapp -eq $mynewvapp}) | get-cinetworkadapter | where-object {$_.Primary}

	<#connect the primary NIC for the VM to the vAPP network and get the IP address assigned from the pool #>
	echo $("   Connecting the VM's primary NIC to the specified vAPP network...")
	$mynewvmIP = (set-cinetworkadapter -networkadapter $mynewvmnic -vappnetwork $myNewvappnetwork -ipaddressallocationmode Pool -connected $True) | select IPaddress
	<#check to see $mynewvmIP is not blank #>
<#end foreach()#>
	
<#start the vApp and get the status of the start attempt #>
echo $("Starting the vAPP...")
$mynewVMPowerStatus = start-civapp -vapp $myNewvApp | select status

