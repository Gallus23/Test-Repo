#Variable declaration
param(
	[string]$Location
	)
	
add-pssnapin -name VMware.VimAutomation.Core


function Get-FolderPath{
<#
.SYNOPSIS
  Returns the folderpath for a folder
.DESCRIPTION
  The function will return the complete folderpath for
  a given folder, optionally with the "hidden" folders
  included. The function also indicats if it is a "blue"
  or "yellow" folder.
.NOTES
  Authors:  Luc Dekens
.PARAMETER Folder
  On or more folders
.PARAMETER ShowHidden
  Switch to specify if "hidden" folders should be included
  in the returned path. The default is $false.
.EXAMPLE
  PS> Get-FolderPath -Folder (Get-Folder -Name "MyFolder")
.EXAMPLE
  PS> Get-Folder | Get-FolderPath -ShowHidden:$true
#>
 
  param(
  [parameter(valuefrompipeline = $true,
  position = 0,
  HelpMessage = "Enter a folder")]
  [VMware.VimAutomation.ViCore.Impl.V1.Inventory.FolderImpl[]]$Folder,
  [switch]$ShowHidden = $false
  )
 
  begin{
    $excludedNames = "Datacenters","vm","host"
  }
 
  process{
    $Folder | %{
      $fld = $_.Extensiondata
      $fldType = "yellow"
      if($fld.ChildType -contains "VirtualMachine"){
        $fldType = "blue"
      }
      $path = $fld.Name
      while($fld.Parent){
        $fld = Get-View $fld.Parent
        if((!$ShowHidden -and $excludedNames -notcontains $fld.Name) -or $ShowHidden){
          $path = $fld.Name + "\" + $path
        }
      }
      $row = "" | Select Name,Path,Type
      $row.Name = $_.Name
      $row.Path = $path
      $row.Type = $fldType
      $row
    }
  }
}

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
$outputfile = "D:\Software\Scripts\vcenterfolders.csv"

Write-Host "Connecting to vCenter" -foregroundcolor "magenta" 
#Connect-VIServer -Server $vCenterIPorFQDN -User $vCenterUsername -Password $vCenterPassword

Get-Folder | Get-FolderPath | where{$_.Type -eq "blue"} | select path  | sort path  | Export-Csv  $outputfile

#--------------------------------------------------------------------------------------------------------------------------------------
#Disconnect the vCenter
write-host "Disconnecting vSphere......."
disconnect-viserver -server * -Confirm:$false -force