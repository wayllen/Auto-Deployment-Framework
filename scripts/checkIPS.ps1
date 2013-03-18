param($Param_NewestFolder,$BuildType)

$masterLog = ".\masterlog.log"



#insert script start date into log
Write-Output `
"#------------------------------------------------
#checkIPS.ps1 started: $(Get-Date -f G)      
#------------------------------------------------" >> $masterLog

#check if IPS needs to be installed locally
Write-Output "$(Get-Date -f G)`tChecking if IPS is installed" >> $masterLog
if(-not (Get-WmiObject -Class Win32_Product -Filter "Name='IGT Provisioning System'"))
{
    if ($BuildType -eq "Man")
    {
        #IPS is not installed, install it
        Write-Host "$(Get-Date -f G)`tIPS is not installed, running setup from $($($Param_NewestFolder + '\ADVInstallTools\Image\IPS\Client\IPSSetup.exe') + ' /s /v/qn')" >> $masterLog
        Invoke-Expression "$($($Param_NewestFolder + '\ADVANTAGE INSTALLATION TOOLS\Image\IPS\Client\IPSSetup.exe') + ' /s /v/qn')"
        sleep -Seconds 60
    }
    elseif ($BuildType -eq "Auto")
    {
        #IPS is not installed, install it
        Write-Host "$(Get-Date -f G)`tIPS is not installed, running setup from $($($Param_NewestFolder.FullName + '\ADVInstallTools\Image\IPS\Client\IPSSetup.exe') + ' /s /v/qn')" >> $masterLog
        Invoke-Expression "$($($Param_NewestFolder.FullName + '\ADVInstallTools\Image\IPS\Client\IPSSetup.exe') + ' /s /v/qn')"
        sleep -Seconds 60
    }
}

#check if IPS needs to be upgraded locally
elseif ($BuildType -eq "Man")
{
    if([decimal](((Get-FileVersionInfo $($Param_NewestFolder + "\ADVInstallTools\Image\IPS\Client\IPSSetup.exe")).ProductVersion) -replace "\D", "") -gt (((Get-WmiObject -Class Win32_Product -Filter "Name='IGT Provisioning System'").Version) -replace "\D", ""))
    {
        #IPS needs to be upgraded, uninstall current version of IPS
        Write-Output "$(Get-Date -f G)`tNew version of IPS detected, uninstalling the current version" >> $masterLog
        (Get-WmiObject -Class Win32_Product -Filter "Name='IGT Provisioning System'").Uninstall()
        sleep -Seconds 60
    
        #install new version of IPS
        Write-Output "$(Get-Date -f G)`tInstalling new version of IPS from $($($Param_NewestFolder + '\ADVInstallTools\Image\IPS\Client\IPSSetup.exe') + ' /s /v/qn')" >> $masterLog
        Invoke-Expression "$($($Param_NewestFolder + '\ADVInstallTools\Image\IPS\Client\IPSSetup.exe') + ' /s /v/qn')"
        sleep -Seconds 60
    }
}
elseif ($BuildType -eq "Auto")
{
  if([decimal](((Get-FileVersionInfo $($Param_NewestFolder.FullName + "\ADVInstallTools\Image\IPS\Client\IPSSetup.exe")).ProductVersion) -replace "\D", "") -gt (((Get-WmiObject -Class Win32_Product -Filter "Name='IGT Provisioning System'").Version) -replace "\D", ""))
  {
    #IPS needs to be upgraded, uninstall current version of IPS
    Write-Output "$(Get-Date -f G)`tNew version of IPS detected, uninstalling the current version" >> $masterLog
    (Get-WmiObject -Class Win32_Product -Filter "Name='IGT Provisioning System'").Uninstall()
    sleep -Seconds 60
    
    #install new version of IPS
    Write-Output "$(Get-Date -f G)`tInstalling new version of IPS from $($($Param_NewestFolder.FullName + '\ADVInstallTools\Image\IPS\Client\IPSSetup.exe') + ' /s /v/qn')" >> $masterLog
    Invoke-Expression "$($($Param_NewestFolder.FullName + '\ADVInstallTools\Image\IPS\Client\IPSSetup.exe') + ' /s /v/qn')"
    sleep -Seconds 60
   }
}
else
{
    Write-Output "$(Get-Date -f G)`tIPS is installed and matches the current build" >> $masterLog
}
