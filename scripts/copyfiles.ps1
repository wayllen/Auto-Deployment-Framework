param($Param_localBuildFolder,$Param_NewestFolder)


Write-Host "The selected folder is $Param_NewestFolder | The local build folder is $Param_localBuildFolder"
Copy-Item "$Param_NewestFolder\*" -Destination $Param_localBuildFolder -Recurse -Force
