param($installType,$BuildFolder,$Upgrade)

#import powershell community extensions for increased functionality
Import-Module Pscx 

#import vmware cli
Add-PSSnapin "Vmware.VimAutomation.Core" -ErrorAction SilentlyContinue

#create log
$masterLog = ".\masterlog.log"
if(-not (Test-Path $masterLog)){New-Item $masterLog -Type File}

#vm vsphere server
$vsphereServer = "your vsphere server ip"
$vsphereUser = "administrator"
$vspherePass = 'Password'
$VMlist = get-content .\config\vmlist.txt

#connect to the virtual server the VM's are on
Connect-VIServer -Server $vsphereServer -Protocol https -User $vsphereUser -Password $vspherePass

#insert script start date into log
Write-Output `
"#################################################
#Auto-Master.ps1 started: $(Get-Date -f G)      
#################################################" >> $masterLog

#start loop to initiate the install of a new build

do 
{
    write-host "starting to loop ~~~~~~~~~~~~~~~~~~~~~~~"
    $LoopVariable = 1
    if ($installType -eq "Man")
    {   
        Write-Host "The Install Type is $installType! and loop variable++"
        $LoopVariable++

    }
   

#insert log entry every time the script loops
Write-Output `
"######################################################
#Check for new Build started: $(Get-Date -f G)      
######################################################" >> $masterLog


    if ($installType -eq "Auto")
    {
        #get the newest build
        $NewestFolder = Get-Item $($BuildFolder + "*") | Sort-Object LastWriteTime | Select-Object -Last 1
        Write-Output "$(Get-Date -f G)`tUsing newest build folder:`t`t`t`t$NewestFolder" >> $masterLog
        Write-host "$(Get-Date -f G)`tUsing newest build folder:`t`t`t`t$NewestFolder"
    
        #set the path for the where the success.txt file should be
        $Success = $NewestFolder.FullName + "\success.txt"
        Write-Output "$(Get-Date -f G)`tLooking for success file here:`t`t`t$Success" >> $masterLog
        Write-host "$(Get-Date -f G)`tLooking for success file here:`t`t`t$Success"
    
        #parse the build number out of the folder name
        $BuildNumber = $NewestFolder.FullName.replace($BuildFolder, "")
        Write-Output "$(Get-Date -f G)`tBuild number parsed is:`t`t`t`t`t$BuildNumber" >> $masterLog
        Write-host "$(Get-Date -f G)`tBuild number parsed is:`t`t`t`t`t$BuildNumber"
    }
    elseif ($installType -eq "Man")
    {
        #get the selected build
        $NewestFolder = & .\GetListBox.ps1 $BuildFolder $Upgrade
        write-host "========The seleted folder is $NewestFolder ========"
        Write-Output "$(Get-Date -f G)`tUsing selected build folder:`t`t`t`t$NewestFolder" >> $masterLog
    
        #set the path for the where the success.txt file should be
        $Success = $NewestFolder + "\success.txt"
        Write-Host "$(Get-Date -f G)`tLooking for success file here:`t`t`t$Success"
        Write-Output "$(Get-Date -f G)`tLooking for success file here:`t`t`t$Success" >> $masterLog
    
        #parse the build number out of the folder name
        $BuildNumber = $NewestFolder.replace($BuildFolder, "")
        Write-Host "$(Get-Date -f G)`tBuild number parsed is:`t`t`t`t`t$BuildNumber"
        Write-Output "$(Get-Date -f G)`tBuild number parsed is:`t`t`t`t`t$BuildNumber" >> $masterLog
    }
    else
    {
        Write-Host "$(Get-Date -f G)`tThe option:$InstallType is not valid" >>$masterLog
    }
 
 
    
    #set the path for the buildnum.txt location, create it if it doesn't exist and insert a character so the checkbuild.ps1 script works
    $BN = ".\buildnum.txt"
    if(-not (Test-Path $BN))
    {
        write-host "Create the build number file."
        New-Item $BN -Type File
        "1">$BN
    }
    Write-Output "$(Get-Date -f G)`tUsing build number file location:`t`t$BN" >> $masterLog
    
    #get the last successfull build number installed
    $BuildNumberInstalled = Get-Content $BN
    Write-Output "$(Get-Date -f G)`tThe current build installed is:`t`t$BuildNumberInstalled" >> $masterLog
    Write-host "$(Get-Date -f G)`tThe current build installed is:`t`t$BuildNumberInstalled"
    
    #set the path for the local build folder
    $localBuildFolder = ".\build"
    Write-Output "$(Get-Date -f G)`tWhere the build is copied to:`t`t`t$localBuildFolder" >> $masterLog
    
    
    #path to the IPS remote CSV
    $csvLocation = ".\config\IPSremoteALL-bvt1.csv"
    Write-Output "$(Get-Date -f G)`tPath to the remote csv:`t`t`t`t$csvLocation" >> $masterLog
    
    #IPS remote install command
    $IPSinstallcmd = 'C:\"Program Files (x86)"\"IGT Systems"\"Provisioning System"\Bin\IPSCMD.exe /ignoreerrors="True" /manifest=".\config\CRDC-9_1-BVT-20110221.xml" /remoteMachines=".\config\IPSremoteALL-bvt1.csv" /user="username" /password="password"'

    Write-Output "$(Get-Date -f G)`tIPS remote install command:`t`t`t$csvLocation" >> $masterLog
    
    #Host for SB
    #$sbHost = "sbcorenew"
    
        
    #Check if the success file exists and the build number on the SAN is newer than the one installed  
    Write-Output "$(Get-Date -f G)`tChecking for new build" >> $masterLog
    $checkBuild = & c:\autoinstall\scripts\checkbuild.ps1 $success $BuildNumber $BuildNumberInstalled
    Write-Output "$(Get-Date -f G)`tEnd of checkbuild.ps1" >> $masterLog
    
    if($checkBuild -eq "Found")
    {
        Write-Host "New build found ++++++++."

        
        #Copy the build locally
        Write-Host "Starting to copy build to local folder."
        & .\scripts\copyBuildLocal.ps1 $localBuildFolder $NewestFolder
        Write-Output "$(Get-Date -f G)`tEnd of copyBuildLocal.ps1" >> $masterLog
        Write-Host "$(Get-Date -f G)`tEnd of copyBuildLocal.ps1"
        
        #Restart VM before uninstall
        Write-Host "Starting to restart VM"
        & .\scripts\restartVMs.ps1 $VMlist
        Write-Host "Sleep 20s before check vm connection."
        sleep -Seconds 20
        
        #Check VM connections    
        $checkConnections = & .\scripts\connectioncheck.ps1 $csvLocation
        Write-Host "$(Get-Date -f G)`tEnd of connectioncheck.ps1" 
        
        if($checkConnections -ne 1)
        {
            Write-Host "$(Get-Date -f G)`tCommunication not established with one or more hosts, end script" 
        }
        else
        {
                        
            #Uninstall IGT products that is currently installed
            write-host "uninstall the build that is currently installed"
            $uninstallStatus = & .\scripts\uninstallBuild.ps1 $csvLocation          
            write-host "The return value of uninstall is $uninstallStatus !"
            Write-Output "$(Get-Date -f G)`tEnd of uninstallBuild.ps1" >> $masterLog
            if($uninstallStatus[1] -eq 0)
             {
                
                #the sb install
               # & c:\autoinstall\scripts\sbInstall.ps1 $NewestFolder $sbHost
               # Write-Output "$(Get-Date -f G)`tEnd of sbInstall.ps1" >> $masterLog

              #Restart VM after uninstall
              Write-Host "Starting to restart VM"
              & .\scripts\restartVMs.ps1 $VMlist 
                           
                # Update the build number
                $BuildNumber > $BN
             }
             else
              {
                Write-Host "$(Get-Date -f G)`tUnable to uninstall IGT applications, script end" 
                Write-Host "The installation process can not start!"
                break
                Write-Host "Exit the program!"
              }        
        
         }
 
               
        #Check VM connections     
        $checkConnections = & .\scripts\connectioncheck.ps1 $csvLocation
        Write-Host "$(Get-Date -f G)`tEnd of connectioncheck.ps1" 
        
        if($checkConnections -ne 1)
        {
            Write-Host "$(Get-Date -f G)`tCommunication not established with one or more hosts, end script" 
        }
        else
        {
                #Check if IPS needs to installed or upgraded locally
                 Write-Output "Check if IPS needs to installed or upgraded locally"
                & .\scripts\checkIPS.ps1 $NewestFolder $installType
                Write-Output "$(Get-Date -f G)`tEnd of checkIPS.ps1" >> $masterLog
        
                #begin IPS remote install               
                write-host "begin IPS remote install."
                & .\scripts\remoteInstall.ps1 $IPSinstallcmd
                Write-Output "$(Get-Date -f G)`tEnd of remoteInstall.ps1" >> $masterLog
                
                #begin validation
                & .\scripts\validate1.9.ps1
                
        
                #Invoke BVT framework to execute test plan.
                
        }
    }
    
    else
    {
        if($checkBuild -eq "Waiting")
        {
            Write-Output "$(Get-Date -f G)`tNew build found but incomplete, waiting 10 minutes" >> $masterLog
            Write-Host "$(Get-Date -f G)`tNew build found but incomplete, waiting 10 minutes"
            sleep -Seconds 600
        }
        elseif($checkBuild -eq "None")
        {
            Write-Output "$(Get-Date -f G)`tNew build not found, waiting 60 minutes" >> $masterLog
            Write-Host "$(Get-Date -f G)`tNew build not found, waiting 60 minutes"
            sleep -Seconds 3600
        }
        else
        {
            Write-Output "$(Get-Date -f G)`tYou broke the script, fix it!" >> $masterLog
            Write-Host "$(Get-Date -f G)`tYou broke the script, fix it!"
        }
    }    


}# end of do{}
while ($LoopVariable -eq 1) 
#while ($true) 


