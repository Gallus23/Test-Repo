Function Create-HashTable() {

<#
.SYNOPSIS
Creates a Hash Table specifically for use with the Create-Chart Function.

.DESCRIPTION
Creates a Hash Table specifically for use with the Create-Chart Function (Shogan.tech script). Limitation is that your Cmdlet query cannot contain double quote marks or $_ variables - this is because of the Invoke-Expression used in this Function. Any suggestions to fix this and still work with the Create-Chart function would be much appreciated!

.PARAMETER Cmdlet
The name of the cmdlet to use to fetch data. Make sure it fetches the properties of the objects you wish to chart.

.PARAMETER NameProperty
The name of the property to be used in the Chart for each data point name.

.PARAMETER ValueProperty
The name of the property to be used in the Chart for each data point value.

.EXAMPLE
PS F:\> Create-Hashtable -Cmdlet Get-VMHost -NameProperty Name -ValueProperty MemoryUsageMB

.EXAMPLE
PS F:\> Create-Hashtable -Cmdlet Get-VM -NameProperty Name -ValueProperty NumCpu

.EXAMPLE 
PS F:\> Create-Hashtable -Cmdlet Get-Datastore -NameProperty Name -ValueProperty CapacityMB

.LINK
http://www.shogan.co.uk

.NOTES
Created by: Sean Duffy
Date: 27/02/2012
#>

[CmdletBinding()]
param(
[Parameter(Position=0,Mandatory=$true,HelpMessage="Specify your cmdlet query here. Make sure it fetches the properties of the objects you wish to chart.",
ValueFromPipeline=$false,ValueFromPipelineByPropertyName=$true)]
[String]
$Cmdlet,
[Parameter(Position=1,Mandatory=$true,HelpMessage="This is the property name you wish to use on the Chart - most useful would be the 'Name' Property if the cmdlet generates this for each object.",
ValueFromPipeline=$false,ValueFromPipelineByPropertyName=$true)]
[String]
$NameProperty,
[Parameter(Position=2,Mandatory=$true,HelpMessage="This should be the name of a property that will supply a value for each object on the chart. E.g. 'NumCPU' or 'FreeSpaceMB'",
ValueFromPipeline=$false,ValueFromPipelineByPropertyName=$true)]
[String]
$ValueProperty
)

process {

$HashTable = @{}
$Query = Invoke-Expression "$Cmdlet"
foreach ($object in $Query) {
	$HashTable.Add($object.$NameProperty,$object.$ValueProperty)
}

return $HashTable

}
}