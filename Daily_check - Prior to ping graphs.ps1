#Variable declaration
param(
	[string]$Location,
	[string]$TSM
	)
	
add-pssnapin -name VMware.VimAutomation.Core

#Test connection local datacenter folder
Write-Host "Checking for local Datacenter Folder" -foregroundcolor "magenta" 
if(!(Test-path D:\myStackOps\Datacenters\$location))
{
write-host "No Datacenter Folder found, please create if required. Exiting " -foregroundcolor "red" 
exit
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
$OutputPath = "D:\myStackOps\datacenters\" + $location + "\" 	#Location where you want to place generated report
$date = Get-Date -format s
$outputfile = $OutputPath + $date.substring(0,10) + ".html"

Write-Host "Connecting to vCenter" -foregroundcolor "magenta" 
Connect-VIServer -Server $vCenterIPorFQDN -User $vCenterUsername -Password $vCenterPassword

#--------------------------------------------------------------------------------------------------------------------------------------
#This is the CSS used to add the style to the report

$Css="<style>
body {
    font-family: Verdana, sans-serif;
    font-size: 14px;
	color: #666666;
	background: #FEFEFE;
}
#title{
	color:#10259C;
	font-size: 30px;
	font-weight: bold;
	padding-top:25px;
	margin-left:35px;
	height: 50px;
}
#subtitle{
	font-size: 11px;
	margin-left:35px;
}
#main {
	position:relative;
	padding-top:10px;
	padding-left:10px;
	padding-bottom:10px;
	padding-right:10px;
}
#box1{
	position:absolute;
	background: #F8F8F8;
	border: 1px solid #DCDCDC;
	margin-left:10px;
	padding-top:10px;
	padding-left:10px;
	padding-bottom:10px;
	padding-right:10px;
}
#boxheader{
	font-family: Arial, sans-serif;
	padding: 5px 20px;
	position: relative;
	z-index: 20;
	display: block;
	height: 30px;
	color: #777;
	
	line-height: 33px;
	font-size: 19px;
	background: #fff;
	background: -moz-linear-gradient(top, #ffffff 1%, #eaeaea 100%);
	background: -webkit-gradient(linear, left top, left bottom, color-stop(1%,#ffffff), color-stop(100%,#eaeaea));
	background: -webkit-linear-gradient(top, #ffffff 1%,#eaeaea 100%);
	background: -o-linear-gradient(top, #ffffff 1%,#eaeaea 100%);
	background: -ms-linear-gradient(top, #ffffff 1%,#eaeaea 100%);
	background: linear-gradient(top, #ffffff 1%,#eaeaea 100%);
	filter: progid:DXImageTransform.Microsoft.gradient( startColorstr='#ffffff', endColorstr='#eaeaea',GradientType=0 );
	box-shadow: 
		0px 0px 0px 1px rgba(155,155,155,0.3), 
		1px 0px 0px 0px rgba(255,255,255,0.9) inset, 
		0px 2px 2px rgba(0,0,0,0.1);
}

table{
	width:100%;
	border-collapse:collapse;
}
table td, table th {
	border:1px solid #10259C;
	padding:3px 7px 2px 7px;
}
table th {
	text-align:left;
	padding-top:5px;
	padding-bottom:4px;
	background-color:#10259C;
color:#fff;
}
table tr.alt td {
	color:#000;
	background-color:#EAF2D3;
}
</style>"

#--------------------------------------------------------------------------------------------------------------------------------------
#This is the javascript used to dectect warnings and erros and colour the cells appropriately.
$htmlheader = @"
<script src="http://ajax.googleapis.com/ajax/libs/jquery/1.8.2/jquery.min.js"></script>
<script type="text/javascript">
`$(document).ready(function(){
  `$( "td:contains('mystack-warn')" ).css('background-color', '#FDF099'); //If yellow alarm triggered set cell background color to yellow
	`$( "td:contains('mystack-warn')" ).text('Warning'); //Replace text 'yellow' with 'Warning'
	`$( "td:contains('mystack-alarm')" ).css('background-color', '#FCC' ); //If red alarm triggered set cell background color to red
	`$( "td:contains('mystack-alarm')" ).text('Alert'); //Replace text 'mystack-alarm' with 'Alert'
	`$( "td:contains('mystack-normal')" ).css('background-color', '#C8DC80' ); //If red alarm triggered set cell background color to red
});
</script>
		
"@
#--------------------------------------------------------------------------------------------------------------------------------------
#These are the sections of css for the report
$PageBoxOpener="<div id='box1'>"
$BoxContentOpener="<div id='boxcontent'>"
$PageBoxCloser="</div>"
$br="<br>" #This should have been defined in CSS but if you need new line you could also use it this way
#--------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------
#This where the checks begin
#--------------------------------------------------------------------------------------------------------------------------------------
#List Status of DSVA VM's.
write-host "Getting DSVA information......."
$ReportDSVA="<div id='boxheader'>Check DSVA's </div>"

$getdsva=get-vm -name *DSVA* | select name, vmhost, MemoryGB, numcpu, powerstate | sort-object name 
  
$getdsva | Add-Member -type NoteProperty -name myStatus -value "mystack-normal"

foreach($dsva in $getdsva)
{
        
    if ($dsva.MemoryGB -ne 8) 
    {
    $dsva.myStatus = "mystack-alarm"
    write-host "memory issue : " $dsva.name $dsva.MemoryGB $dsva.myStatus
    }

    if ($dsva.numcpu -ne 4) 
    {
    $dsva.myStatus = "mystack-alarm"
    write-host "cpu issue : " $dsva.name $dsva.numcpu $dsva.myStatus
    }

    if ($dsva.powerstate -ne "PoweredOn") 
    {
    $dsva.mystatus = "mystack-alarm"
    write-host "power issue : " $dsva.name $dsva.powerstate $dsva.myStatus
    }

}

$getdsva = $getdsva | ConvertTo-Html -Fragment

#--------------------------------------------------------------------------------------------------------------------------------------
#List Status of Temp EdgeGateway VM's.
write-host "Getting Temp EdgeGateway information......."
$Reportremp="<div id='boxheader'>Check Temp Edge Gateways </div>"
$gettemp=get-vm -name Temporary* | select name, vmhost, MemoryGB, powerstate | sort-object name

$gettemp | Add-Member -type NoteProperty -name myStatus -value 'mystack-normal'

foreach($tempedge in $gettemp)
{

    if ($tempedge.powerstate -ne "PoweredOn")
     {
       $tempedge.mystatus = "mystack-alarm"
       write-host "power issue : " $tempedge.name $tempedge.powerstate $tempedge.myStatus
     }
}

$gettemp = $gettemp | ConvertTo-Html -Fragment

#--------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------
#Get Host Information
write-host "Calculating Host Stats for last 24hrs......."
$High_cpu_warn = 60
$High_cpu_alert = 80
$high_mem_warn = 60
$high_mem_alert = 80

$ReportVmHost="<div id='boxheader'>Host Information $Location Stats for the last 24hrs </div> <div id='subtitle'> <p>Warning set for Average memory and CPU at level $High_cpu_warn% and Alert level set at $High_cpu_alert% </p> </div>"
#$VmHost=Get-VMHost | Select-Object @{Name = 'Host'; Expression = {$_.Name}},ConnectionState,@{Name = 'Cpu_Percent'; Expression = {"{0:N2}" -f ($_.CpuUsageMhz/ $_.CpuTotalMhz) * 100 }}, @{Name = 'Memory_Percent'; Expression = {"{0:N2}" -f ($_.MemoryUsageGB /  $_.MemoryTotalGB) * 100}} | ConvertTo-HTML -Fragment
$allhosts = @()
$hosts = Get-VMHost

foreach($vmHost in $hosts){
  $hoststat = "" | Select HostName, ConnectionState, MemMax, MemAvg, MemMin, CPUMax, CPUAvg, CPUMin
  $hoststat.HostName = $vmHost.name
  $hoststat.connectionstate = $vmhost.ConnectionState
  
  $statcpu = Get-Stat -Entity ($vmHost)-start (get-date).AddDays(-1) -Finish (Get-Date)-MaxSamples 10000 -stat cpu.usage.average
  $statmem = Get-Stat -Entity ($vmHost)-start (get-date).AddDays(-1) -Finish (Get-Date)-MaxSamples 10000 -stat mem.usage.average

  $cpu = $statcpu | Measure-Object -Property value -Average -Maximum -Minimum
  $mem = $statmem | Measure-Object -Property value -Average -Maximum -Minimum
  
  $hoststat.CPUMax = $cpu.Maximum
  $hoststat.CPUAvg = $cpu.Average
  
  $hoststat.MemMax = $mem.Maximum
  $hoststat.MemAvg = $mem.Average
  
  $hoststat | Add-Member -type NoteProperty -name Status -value 'mystack-normal'
  
  if ($hoststat.CPUAvg -gt $High_cpu_warn)
  {
  $hoststat.Status = "mystack-warn"
  }
  if ($hoststat.CPUAvg -gt $High_cpu_alert)
  {
  $hoststat.status = "mystack-alarm"
  }
  
  if ($hoststat.MemAvg -gt $High_mem_warn)
  {
  $hoststat.status = "mystack-warn"
  }
  if ($hoststat.MemAvg -gt $High_mem_alert)
  {
  $hoststat.status = "mystack-alarm"
  }
  
  if ($hoststat.connectionstate -ne "Connected")
  {
  $hoststat.status = "mystack-alarm"
  }
    
  $allhosts += $hoststat
}
$VmHost = $allhosts | Select HostName,status, ConnectionState, @{Name = 'Max_Mem_%'; Expression = {"{0:N2}" -f $_.MemMax}} , @{Name = 'Ave_Mem_%'; Expression = {"{0:N2}" -f $_.MemAvg}}, @{Name = 'Max_CPU_%'; Expression = {"{0:N2}" -f $_.CPUMax}}, @{Name = 'Ave_CPU_%'; Expression = {"{0:N2}" -f $_.CPUAvg}} | sort-object hostname | ConvertTo-HTML -Fragment

#--------------------------------------------------------------------------------------------------------------------------------------
#Get Datastore Stats	
write-host "Pulling Datastore information......"
$datstore_warn_level = 30
$datstore_alert_level = 20 
$ReportGetDatastore="<div id='boxheader'>DataStore Stats </div> <div id='subtitle'> <p> Warning level set at $datstore_warn_level% and alert level $datstore_alert_level% </p></div>"


$datastores=get-datastore 
ForEach ($ds in $datastores)
{  
$txtpercent = ($ds.FreeSpaceMB /  $ds.CapacityMB) * 100
  $txtpercenttrunc = "{0:N2}" -f $txtpercent
  $percentfree = [decimal]$txtpercenttrunc
  
  write-host "capacity is "  $ds.CapacityGB "percent free is " $percentfree
  
if ($ds.CapacityGB -gt 10000) 
	{
	$datstore_warn_level = 11
	$datstore_alert_level = 4 
	}

write-host 	"warm level is " $datstore_warn_level " alert level is " $datstore_alert_level

  $ds | Add-Member -type NoteProperty -name PercentFree -value $PercentFree  
  
  if ($PercentFree -lt $datstore_alert_level) 
  {
	$ds | Add-Member -type NoteProperty -name Status -value 'mystack-alarm'  
  }
  else
  {
	if ($PercentFree -lt $datstore_warn_level)
	{
	$ds | Add-Member -type NoteProperty -name Status -value 'mystack-warn'  
	}
	else
	{
	$ds | Add-Member -type NoteProperty -name Status -value 'mystack-normal'
	}
  }
} 

$getdatastore = $datastores | select-object Name, status, CapacityGB, @{Name = 'FreeGB'; Expression = {"{0:N2}" -f $_.FreeSpaceGB}}, PercentFree | Sort-Object PercentFree  | ConvertTo-HTML -Fragment

#--------------------------------------------------------------------------------------------------------------------------------------
#Get Host Based Alarms
write-host "Pulling Host based Alarms......."

$ReportGetalarms="<div id='boxheader'>Host based alarms </div>"
$hosts = Get-VMHost | Get-View #Retrieve all hosts from vCenter
 
foreach ($esxihost in $hosts){ 												#For each Host
    foreach($triggered in $esxihost.TriggeredAlarmState){ 					#For each triggered alarm of each host
            $arrayline={} | Select HostName, AlarmType, AlarmInformations 	#Initialize line
            $alarmDefinition = Get-View -Id $triggered.Alarm 				#Get info on Alarm
            $arrayline.HostName = $esxihost.Name 							#Get host which has this alarm triggered
			$arrayline.AlarmType = $triggered.OverallStatus 				#Get if this is a Warning or an Alert
            if ($arrayline.AlarmType -eq "red")
			{
			$arrayline.AlarmType = "mystack-alarm"
			}
			if ($arrayline.AlarmType -eq "yellow")
			{
			$arrayline.AlarmType = "mystack-warn"
			}
			$arrayline.AlarmInformations = $alarmDefinition.Info.Name 		#Get infos about alarm
            $HostList += $arrayline 										#Add line to array
			$HostList = @($HostList) 										#Post-Declare this is an array
    }
}

$getalarms = $HostList | select HostName, AlarmType, AlarmInformations | ConvertTo-HTML -Fragment

#--------------------------------------------------------------------------------------------------------------------------------------
#Error Events in the last Day
write-host "Pulling all Warning and Errors events for last 24hrs......."

$ReportGetevents="<div id='boxheader'>Error Events in the last day </div>"
$Getevents = Get-VIEvent  -types error -Start (Get-Date).AddDays(-1) | sort-object createdtime -descending | select CreatedTime, Username, FullFormattedMessage | ConvertTo-HTML -Fragment
#--------------------------------------------------------------------------------------------------------------------------------------
#Disconnect the vCenter
write-host "Disconnecting vSphere......."
disconnect-viserver -server * -Confirm:$false -force

#--------------------------------------------------------------------------------------------------------------------------------------
#Create HTML report
write-host "Creating Page......"

#Add a new line like below for each section of the report

$htmlbody = "$br $ReportVmHost $BoxContentOpener $VmHost $PageBoxCloser "
$htmlbody = $htmlbody + "$br $ReportGetDatastore $BoxContentOpener $getdatastore $PageBoxCloser "

$htmlbody = $htmlbody + "$br $Reportdsva $BoxContentOpener $getdsva $PageBoxCloser "
$htmlbody = $htmlbody + "$br $Reporttemp $BoxContentOpener $gettemp $PageBoxCloser "


$htmlbody = $htmlbody + "$br $ReportGetalarms $BoxContentOpener $getalarms $PageBoxCloser "
$htmlbody = $htmlbody + "$br $ReportGetevents $BoxContentOpener $Getevents $PageBoxCloser "

ConvertTo-Html -Title "Test Title" -Head "<div id='title'><a href='/default.asp'><img src='/images/Mystack_logo_black.png' alt='Main' style='width:180px;height:60px;border:0'></a>Daily Ops Reporting $location </div>$br<div id='subtitle'>Report generated: $(Get-Date)</div>$htmlheader" -Body " $Css  $htmlbody "  | Out-File $outputfile

write-host "Done"

