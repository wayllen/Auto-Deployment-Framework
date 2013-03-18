param($Param_IPSinstallcmd)

$masterLog = ".\masterlog.log"

#insert script start date into log
Write-Output  "#-------remoteInstall.ps1 started: $(Get-Date -f G)-----" >> $masterLog

#IPS remote install command
Invoke-Expression $Param_IPSinstallcmd
Write-Output "$(Get-Date -f G)`tThe IPS remote install command is:`t`t$Param_IPSinstallcmd" >> $masterLog
