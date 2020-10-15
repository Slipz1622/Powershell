$LogPath = 'C:\Temp\Debug\DNSChanger.log'   
$DNSPrimary = ""                               #enter primary dns server you wish to set here
$DNSSecondary = ""                             #enter secondary dns server you wish to set here
$success = 0
$failed = 0
$successdhcp = 0



Function LogWrite{
   Param ([string]$logstring)
     $Timestamp = Get-Date -Format "[MM-dd-yyyy hh:mm:ss]"
     Add-content $LogPath -value  "$Timestamp $logstring"
}


$ActiveNet = Get-NetConnectionProfile 
$InterfaceName =@( $ActiveNet.InterfaceAlias )

foreach ($interface in $InterfaceName){
$results = netsh interface ipv4 show dns name=$Interface

if(($results | select-string 'DNS servers configured through DHCP:') -match 'DNS servers configured through DHCP:'){
    #checks to see if we are using DHCP for DNS
    logwrite "$interface is using dhcp dns, dont need to touch this one!"
    #Write-Output "Success-DHCP"
    $successdhcp++
    }
else{
    #if not on DHCP attempt to set the DNS Servers
    Logwrite "found interface $Interface using static dns, attempting to set to $DNSPrimary and $DNSSecondary"
    Set-DnsClientServerAddress -InterfaceAlias $Interface -ServerAddresses $DNSPrimary, $DNSSecondary              
    $results2 = netsh interface ipv4 show dns name=$Interface
        
    #Verify that new settings actually took
    If(($results2 | Select-String "$DNSPrimary")-match "$DNSPrimary"){   
        logwrite "successfully changed dns servers on $interface!"
       # Write-Output "Success"
        $success++
    }
    #Report failure
        else{
            Logwrite "Failed to change DNS servers on $interface!"
            #Write-Output "Failed"
            $failed++
    }
}
}

if( $failed -gt 0) { Write-Output "Failed; see logs" }
elseif($successdhcp -eq 0 -and $success -eq 0){ Write-Output "didnt find any connections to change?? this should never happen!!" }
elseif($successdhcp -eq 0 -and $success -gt 0){ Write-Output "success"}
elseif($successdhcp -gt 0 -and $success -gt 0){ Write-Output "success-mixed"}
elseif($successdhcp -gt 0 -and $success -eq 0){ Write-Output "success-DHCP"} 
