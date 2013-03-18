param($Param_Success,$Param_BuildNumber,$Param_BuildNumberInstalled)

$masterLog = ".\masterlog.log"

#insert script start date into log
Write-Output `
"#------------------------------------------------
#checkBuild.ps1 started: $(Get-Date -f G)      
#------------------------------------------------" >> $masterLog

#Check for the success file
$SuccessFound = (Test-Path $Param_Success)
Write-Output "$(Get-Date -f G)`tSuccess found is: $SuccessFound" >> $masterLog
Write-Host "$(Get-Date -f G)`tSuccess found is: $SuccessFound"

#Compare the Builds(the periods are taken out of the build number and then it's converted to a decimal to assist in the comparison)
$NewBNFound = (([decimal]($Param_BuildNumber -replace "\D", "")) -gt ([decimal]($Param_BuildNumberInstalled -replace "\D", "")))
Write-Output "$(Get-Date -f G)`tNew build found is: $NewBNFound" >> $masterLog

if(-not $NewBNFound -and -not $SuccessFound)
{
    $Return_NewBuildStatus = "None"
}
elseif(-not $NewBNFound -and $SuccessFound)
{
    $Return_NewBuildStatus = "None"
}
elseif($NewBNFound -and -not $SuccessFound)
{
    $Return_NewBuildStatus = "Waiting"
}
elseif($NewBNFound -and $SuccessFound)
{
    $Return_NewBuildStatus = "Found"
}
Write-Output "$(Get-Date -f G)`tReturning status $Return_NewBuildStatus" >> $masterLog

return($Return_NewBuildStatus)
