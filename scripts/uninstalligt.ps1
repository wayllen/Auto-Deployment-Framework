#disable all igt services and stop them
$Services = Get-Service | Where-Object {$_.Name -like 'ADI*' -or $_.Name -like 'IGT*' -or $_.Name -like 'ezpay*' -or $_.Name -like 'Advantage *' -or $_.Name -like 'ACXServices*' -or $_.Name -like 'ARC*' -or $_.Name -like 'IB *'}
if ($Services) {
    foreach ($service in $Services) {
        $servicename = $service.Name
        $servicestatus = $service.Status
        Set-Service -Name $servicename -StartupType Disabled
        $Processes = Get-Process | Where-Object {$_.Name -like 'IGT*' -or $_.Name -like 'abstran' -or $_.Name -like 'conc'}
        if ($Processes) {
            foreach($process in $Processes){
                Stop-Process $process.id -Force
            }
        }
        Stop-Service $servicename -Force -ErrorAction SilentlyContinue
    }
}
$products = Get-WmiObject -Class Win32_Product | Where-Object {
$_.Vendor -like "IGT*" -or $_.Vendor -like "International Game Technology"
}
if($products){
  foreach ($product in $products) {
		$product.Uninstall()
	}
}
$Services = Get-Service | Where-Object {$_.Name -like 'ADI*' -or $_.Name -like 'IGT*' -or $_.Name -like 'ezpay*' -or $_.Name -like 'Advantage *' -or $_.Name -like 'ACXServices*' -or $_.Name -like 'ARC*' -or $_.Name -like 'IB *'}
if ($Services) {
    foreach ($service in $Services) {
        $servicename = $service.Name
        C:\WINDOWS\system32\sc.exe delete $servicename
    }
}
$sbxfolder = "C:\Program Files (x86)\IGT Systems\sbX"
if (test-path $sbxfolder) {
    Remove-Item $sbxfolder\* -recurse -Force
    Remove-Item $sbxfolder -Force
}
