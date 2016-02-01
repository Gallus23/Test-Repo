Add-PSSnapin VMware.VimAutomation.Core
Add-PSSnapin vmware.vimautomation.cloud

$VCUsername = "astepga"
$VCPassword = "Bluealert1981_"
$VCoutputfile = "D:\Software\Scripts\temp_vcenter_orgs.csv"
$location = "LO1"
$basefolder = $location + "pvcd"

$VCFQDN=$location + "wpvcdvcs002.dcsprod.dcsroot.local"

Function getvCenterOrgs{
Connect-VIServer -Server $VCFQDN -User $VCUsername -Password $VCPassword

$orgArray = Get-Folder -Location $basefolder -Type VM -NoRecursion | Select -ExpandProperty Name

Out-File -FilePath $VCoutputfile -inputobject "Org,OrgvDC,vApp,VM" -encoding ASCII

ForEach ($org in $orgArray)
{
    $orgName = $org.split()
    #Write-Host "Currently Selected vOrg is: " $orgName[0]

    $vdcArray = Get-Folder -Location $org -NoRecursion -Type VM | Select -ExpandProperty Name

    ForEach ($vdc in $vdcArray)
    {
        $vdcName = $vdc.Split()

        #Write-Host "Listing vApps for vDC " $vdcName[0]
        
        $vAppArray = Get-Folder -Location $vdc -NoRecursion -Type VM | Select -ExpandProperty Name

        ForEach ($vApp in $vAppArray)
        {
            $vAppName = $vApp.Split()

            #Write-Host "Listing VMs under vApp: " $vAppName[0]
            $vmArray = Get-VM -Location $vApp | Select -ExpandProperty Name

            ForEach ($vm in $vmArray)
            {            
                $vmName = $vm.Split()
              
                $csvstring = $orgName[0] + "," + $vdcName[0] + "," + $vAppName[0] + "," + $vmName[0]
                Write-Host "Writing: " $csvstring
                Out-File -FilePath $VCoutputfile -Append -inputobject $csvstring -encoding ASCII
                Clear-Variable vmName
            }
        }
    }
}

Clear-Variable org
Clear-Variable orgArray
Clear-Variable orgName
Clear-Variable vdc
Clear-Variable vdcArray
#Clear-Variable vcdName
Clear-Variable vApp
Clear-Variable vAppArray
Clear-Variable vAppName
Clear-Variable vm
Clear-Variable vmArray
Clear-Variable vmName
Clear-Variable csvstring

#Disconnect from vCenter
write-host "Disconnecting vCenter..."
disconnect-viserver -server * -Confirm:$false -force
}

Function getvCDOrgs{

}

#getvCenterOrgs
getvCDOrgs