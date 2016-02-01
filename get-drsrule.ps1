#Variable declaration
param(
	[string]$Location
	)
	
add-pssnapin -name VMware.VimAutomation.Core


$vCenterIPorFQDN=$location + "wpvcdvcs002.dcsprod.dcsroot.local"

#Test connection to destination vCenter
Write-Host "Testing Connection to vCenter" -foregroundcolor "magenta" 
if(!(Test-Connection -Cn $vCenterIPorFQDN -BufferSize 16 -Count 1 -ea 0 -quiet))
{
write-host "Connection to $vCenterIPorFQDN failed cannot ping" -foregroundcolor "red" 
exit
}

$vCenterUsername = "mystackops@dcsutil.dcsroot.local"
$vCenterPassword = "#0rs3Sh03"
$outputfile = "D:\Software\Scripts\$location-drsrules.csv"

Write-Host "Connecting to vCenter" -foregroundcolor "magenta" 
Connect-VIServer -Server $vCenterIPorFQDN -User $vCenterUsername -Password $vCenterPassword

if (test-path $outputfile )
    {
    Remove-Item -path $outputfile
    }

$clusterName =  Get-Cluster 
$rules = get-cluster -Name $clusterName | Get-DrsRule

foreach($rule in $rules){
  $line = (Get-View -Id $rule.ClusterId).Name
  $line += ("," + $rule.Name + "," + $rule.Enabled + "," + $rule.KeepTogether)
  foreach($vmId in $rule.VMIds){
    $line += ("," + (Get-View -Id $vmId).Name)
  }
  
  if ($line.ToLower().Contains("Temp".ToLower()))
  {
  write-host $line
  # $line | Out-File -Append $outputfile
  }
}


#--------------------------------------------------------------------------------------------------------------------------------------
#Disconnect the vCenter
write-host "Disconnecting vSphere......."
disconnect-viserver -server * -Confirm:$false -force