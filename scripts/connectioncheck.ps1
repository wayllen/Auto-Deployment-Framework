#################################################################
#connectioncheck.ps1                                            #
#check connectivity of the machines in the ips remote deploy csv#
#################################################################
#takes in the path for the csv
param($RemoteCSV)

$masterLog = ".\masterlog.log"

#insert script start date into log
Write-Output `
"#------------------------------------------------
#connectioncheck.ps1 started: $(Get-Date -f G)      
#------------------------------------------------" >> $masterLog

#gather the list of hosts in the IPS remote csv file passed to this script
$hsts = Import-Csv $RemoteCSV
$hsts|ForEach-Object{Write-Host "$(Get-Date -f G)`t$($_.ComputerName) added to host list for connection check"}

#initialize a couple variables to use as the return value of this script
$hstcount = 0
$hstready = @()
foreach ($hst in $hsts) 
{
    Write-Host "$(Get-Date -f G)`tBeginning connection check of $($hst.ComputerName)"
    $ready = 0
    $timeout = get-date
    $hostIPs = [System.Net.DNS]::GetHostAddresses("$($hst.ComputerName)")
    $ip=$hostIPs|ForEach-Object{$_.IPAddressToString}
    if(($ip.GetType()).Name -eq "Object[]")
    {
        $ip = $ip[0]
    }
    while ($ready -eq 0) 
    {
        if(Test-Connection -ComputerName $hst.ComputerName -Quiet)
        {
            Write-Host "$(Get-Date -f G)`tSuccessfully pinged $($hst.ComputerName) "
            $winrmservicestarted = Get-Service -ComputerName $hst.ComputerName -Name WinRM -ErrorAction SilentlyContinue | Where-Object{$_.Status -eq "Running"}
            if ($winrmservicestarted)
            {
                Write-Host "$(Get-Date -f G)`tWinRM service status Running on $($hst.ComputerName)" 
                $remoteTime = Invoke-Command -ComputerName $($hst.ComputerName) -ScriptBlock{get-date} -ErrorAction SilentlyContinue
                if($remoteTime)
                {
                    if(-not ($timeout -gt $remoteTime.AddMinutes(1)) -or -not($timeout -lt $remoteTime.AddMinutes(-1)))
                    {
                        Write-Host "$(Get-Date -f G)`t$($hst.ComputerName) ready" 
                        $ready = 1
                        $hstready += $($hst.ComputerName)
                    }
                    else
                    {
                            Write-Host "$(Get-Date -f G)`tTime Difference, Auto-Master: $timeout`t$($hst.ComputerName): $remoteTime" 
                            $ready = 2
                    }
                }
            }
            else
            {
                Write-Host "$(Get-Date -f G)`tUnable to communicate with WinRM service on $($hst.ComputerName)" 
            }
        }
        elseif($timeout -gt $timeout.AddMinutes(10))
        {
            Write-Host "$($hst.ComputerName) Communication with $($hst.ComputerName) timed out, skipping" 
            $ready = 2
        }
        else
        {
            Write-Host "$($hst.ComputerName) Not ready, Network communication not restored and/or time difference occurred" 
            Start-Sleep -Seconds 5
        }
    }
}
return($hstready.count/$hsts.count)
