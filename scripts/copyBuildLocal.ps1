param($Param_localBuildFolder,$Param_NewestFolder)

$masterLog = ".\masterlog.log"

#insert script start date into log
Write-Output `
"#------------------------------------------------
#copyBuildLocal.ps1 started: $(Get-Date -f G)      
#------------------------------------------------" >> $masterLog

######################################
#copy files to Auto-Master pc locally#
######################################

#make a new build folder, this deletes everything that was in it for the previous build
Write-Output "$(Get-Date -f G)`tDeleting and re-creating the local build folder" >> $masterLog
Remove-Item $Param_localBuildFolder* -recurse -Force -ErrorAction SilentlyContinue
if(-not (test-path $Param_localBuildFolder)){New-Item $Param_localBuildFolder -type directory -ErrorAction SilentlyContinue}

#initialize variables for the progress bar
#$Param_NewestFolderSize = (gci $Param_NewestFolder -recurse | measure-object Length -sum).Sum
#$Param_localBuildFolderSize = (gci $Param_localBuildFolder -recurse | measure-object Length -sum).Sum

#copy everything from the new build to the local build folder
Write-Output "$(Get-Date -f G)`tInvoking c:\autoinstall\scripts\copyfiles.ps1 to copy new build locally" >> $masterLog
& .\scripts\copyfiles.ps1 $Param_localBuildFolder $Param_NewestFolder

