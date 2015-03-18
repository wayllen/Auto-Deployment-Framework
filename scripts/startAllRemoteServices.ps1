$hostList = Get-Content "the path of the host list file."

foreach($vm in $hostList){
    $serviceList = Get-Service -ComputerName $vm | Where-Object {$_.Name -like 'one*' -or $_.DisplayName -like "two*" -or $_.Name -like "three *"} 
    if($serviceList){
        foreach($srv in $serviceList){
            $srvName = $srv.Name
            $srvStatus = $srv.Status
            if($srvStatus -eq 'Stopped'){
                (Get-WmiObject Win32_Service -ComputerName $vm -Filter "Name = '$srvName'").InvokeMethod("StartService",$null)
            }
            
        }
        
    }

}
