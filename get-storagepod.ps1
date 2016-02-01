$storMgr = Get-View StorageResourceManager  
$spec = New-Object VMware.Vim.StorageDrsConfigSpec   
$dsc = Get-Datastorecluster "Gold-Standard"  
$MyVM = "sdrs-test"

get-vm -Datastore $dsc | where {$_.Name -eq $MyVM} | %{  
    $vmEntry = New-Object VMware.Vim.StorageDrsVmConfigSpec              
    $vmEntry.Operation = "add"              
    $vmEntry.Info = New-Object VMware.Vim.StorageDrsVmConfigInfo              
    $vmEntry.Info.Vm = $_.ExtensionData.MoRef              
    $spec.vmConfigSpec += $vmEntry               
}                
$storMgr.ConfigureStorageDrsForPod($dsc.ExtensionData.MoRef,$spec,$true)  