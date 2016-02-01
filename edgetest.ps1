$EdgeGateway = "HED-SL-ARCH-RD-LO1-edge-gateway"
$Edgeview = Search-Cloud -QueryType EdgeGateway -name $EdgeGateway | Get-CIView
	if (!$Edgeview) {
		Write-Warning "Edge Gateway with name $Edgeview not found"
		Exit
	}
    $webclient = New-Object system.net.webclient
    $webclient.Headers.Add("x-vcloud-authorization",$Edgeview.Client.SessionKey)
    $webclient.Headers.Add("accept",$EdgeView.Type + ";version=5.1")
    [xml]$EGWConfXML = $webclient.DownloadString($EdgeView.href)
    $NATRules = $EGWConfXML.EdgeGateway.Configuration.EdgegatewayServiceConfiguration.NatService.Natrule
   
    $NATRules
