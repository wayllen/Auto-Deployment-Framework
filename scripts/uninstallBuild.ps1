param($Param_csvLocation)

#$masterLog = "c:\autoinstall\masterlog.log"

#insert script start date into log
Write-Host `
"#------------------------------------------------
#uninstallBuild.ps1 started: $(Get-Date -f G)      
#------------------------------------------------" 

#create the list of hosts that will be part of a session
$hostlist = Import-Csv $Param_csvLocation|ForEach-Object {$_.ComputerName}
$hostlist|ForEach-Object{Write-Host "$(Get-Date -f G)`t$_ added to session"}

#Create new session
Write-Host "$(Get-Date -f G)`tCreating session" 
$sessionUninstall = New-PSSession $hostlist

#run uninstall script to stop all services, remove files/folders, and uninstall IGT apps
Write-Host "$(Get-Date -f G)`tStarting uninstall job" 
$UninstallJobs = Invoke-Command -Session $sessionUninstall -FilePath c:\autoinstall\scripts\uninstallIGT.ps1 -AsJob

#wait for job to complete
$UninstallJobs|Wait-Job -Timeout 1800

#initialize array for jobresult output
$jobresultoutput = @()

#if the job has more data then check the result of each host in the session
if($UninstallJobs.HasMoreData)
{
    $joberrors = 0
    $jobresults = Receive-Job -Name $UninstallJobs.Name
    foreach($job in $jobresults)
    {
        if($job -eq "[SC] DeleteService SUCCESS")
        {
            #A successful classicadi uninstall deletes the services so we skip those messages
            Write-Host "$(Get-Date -f G)`tSkipping SC delete information" 
        }
        elseif($job.ReturnValue -ne 0)
        {
            $joberrors ++
            $jobresultoutput = $($job.PSComputerName)
            Write-Host "$(Get-Date -f G)`tError uninstalling from $jobresultoutput" 
        }
    }            
}
else
{
    $joberrors = 0
    $jobresultoutput = "Nothing was uninstalled"
    Write-Host "$(Get-Date -f G)`t$jobresultoutput, either everything is already uninstalled or connectivity was lost" 
}

return($joberrors)
