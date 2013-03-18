Function IGTservices ($computerName)
{
    $serviceList = @()
    $productService = Get-Service -ComputerName $computerName | Where {$_.DisplayName -like "IGT*"`
                                                                        -or $_.DisplayName -like "ACX*"`
                                                                        -or $_.DisplayName -like "ADI*"`
                                                                        -or $_.DisplayName -like "ARC*"`
                                                                        -or $_.DisplayName -like "IB*"`
                                                                        -or $_.DisplayName -like "CTA*"`
                                                                        -or $_.DisplayName -like "ezpay_*"`
                                                                        -or $_.DisplayName -like "Advantage*"
                                                                       
                                                                      }
    foreach ($svc in $productService)
    {
        $out = New-Object psobject
        $out | add-member noteproperty Status $svc.Status
        $out | add-member noteproperty IGTservices $svc.Name
        $out | add-member noteproperty Server $computerName
        $serviceList+=$out
    }
    return($serviceList)
}
Function IGTServiceStatus
{
    $servicesRequired = Get-Content c:\autoinstall\validate\IGTservices.txt
    $servicesInstalled = @()
    $servicesInstalled += $HostConf|ForEach-Object{IGTservices($_.ComputerName)}
    $svcStatus=@()
    foreach($svc in $servicesRequired)
    {
        $findservice = $servicesInstalled|ForEach-Object{$_.IGTServices}|Sort-Object|Get-Unique|Select-String -Pattern $svc -SimpleMatch
        #If more than one service returned with same name, then below will got NULL value.
        $svcLoc = ($servicesInstalled | Where-Object {$_.IGTservices -eq $svc}).Server
        $svcStat = ($servicesInstalled | Where-Object {$_.IGTservices -eq $svc}).Status
        #test validation
        if($findservice)
        {
            $found = "Found"
            if($svcStat -eq "Running"){$PF = "Pass"}
            else{$PF = "Fail"} 
        }
        else
        {
            $found ="NOT Found"
            $PF = "Fail"
        }
        if($svcStat -eq "Running"){$PF = "Pass"}
        else{$PF = "Fail"}        
        $out2 = New-Object psobject
        $out2 | Add-Member noteproperty ServiceName $svc
        $out2 | Add-Member noteproperty Check $found
        $out2 | Add-Member noteproperty Status $svcStat        
        $out2 | Add-Member noteproperty Server $svcLoc
        $out2 | Add-Member noteproperty Validation $PF
        $svcStatus += $out2
    }
    return($svcStatus)
}
Function IGTapps ($server)
{
    $productList = @()
    $IGTproducts = Get-WmiObject Win32_Product -ComputerName $server| `
                   Where-Object `
                   {`
                    $_.Vendor -like "IGT*"`
                    -or $_.Vendor -like "International Game Technology*"`
                   }
    foreach ($product in $IGTproducts)
    {
        $out = New-Object psobject
        $out | add-member noteproperty IGTProductName $product.Name
        $out | add-member noteproperty IGTProductCaption $product.Caption
        $out | add-member noteproperty IGTProductVersion $product.Version
        $out | add-member noteproperty Server $server
        $productList+=$out
    }
    return($productList)  
}
Function IGTAppStatus
{
    $appStatus = @()
    $appStatus2 = @()
    foreach($product in $applicationsRequired)
    {
        #search installed applications for each required application
        $findapp = $productsInstalled|ForEach-Object{$_.IGTProductName}|Where-Object{$_ -contains $product}
        $appLoc = ($productsInstalled | Where-Object {$_.IGTProductName -eq $product}).Server
        $appVersion = ($productsInstalled | Where-Object {$_.IGTProductName -eq $product}).IGTProductVersion
        $appOOS = @("IGT Provisioning System","sbX Media Manager Suite","sbX System Framework Suite","sbX Floor Manager suite","sbX Core Application Suite")
        #create an array out of the apps found, this must be done because of apps that are installed on more than one vm
        if($findapp -is [array])
        {
            $a=@()
            $productsInstalled | Where-Object {$_.IGTProductName -eq $product}|ForEach-Object{
                                                                                            $outB = New-Object psobject
                                                                                            $outB|Add-Member noteproperty PN $_.IGTProductName
                                                                                            $outB|Add-Member noteproperty S $_.Server
                                                                                            $outB|Add-Member noteproperty VSN $_.IGTProductVersion
                                                                                            $a+=$outB
                                                                                            }
            foreach ($i in $a)
            {
                $outA = New-Object psobject
                if($findapp)
                {
                    $found = "Found"
                    if($appOOS -contains $i.PN)
                    {
                        $vsn = $i.VSN
                        $PF = "Out of Scope"
                    }
                    else
                    {
                        if($i.VSN -eq $BNcompare)
                        {
                            $vsn = $i.VSN
                            $PF = "Pass"
                        }
                        else
                        {
                            $vsn = "Version mismatch: $($i.VSN)"
                            $PF = "Fail"
                        }
                    }
                }
                else
                {
                    $found ="NOT Found"
                    $PF = "Fail"
                }
                $outA | Add-Member noteproperty ProductName $i.PN
                $outA | Add-Member noteproperty Check $found
                $outA | Add-Member noteproperty Server $i.S
                $outA | Add-Member noteproperty Version $vsn
                $outA | Add-Member noteproperty Validation $PF
                $appStatus2 += $outA
            }
        }
        else
        {
            $out = New-Object psobject
            if($findapp)
            {
                $found = "Found"
                if($appOOS -contains $product)
                {
                    $vsn = $appVersion
                    $PF = "Out of Scope"
                }
                else
                {
                    if($appVersion -eq $BNcompare)
                    {
                        $vsn = $appVersion
                        $PF = "Pass"
                    }
                    else
                    {
                        $vsn = "Version mismatch: $($appVersion)"
                        $PF = "Warning"
                    }
                }
            }
            else
            {
                $found ="NOT Found"
                $PF = "Fail"
            }
            $out | Add-Member noteproperty ProductName $product
            $out | Add-Member noteproperty Check $found
            $out | Add-Member noteproperty Server $appLoc
            $out | Add-Member noteproperty Version $appVersion
            $out | Add-Member noteproperty Validation $PF
            $appStatus += $out
        }
    }
    
    return($appStatus+$appStatus2|Sort-Object Server)
}
Function chkVMs
{
    foreach ($hst in $HostConf) {
        $ready = 0
        while ($ready -eq 0) {
            if (Test-Connection -ComputerName $hst.ComputerName -Quiet){
                $winrmservicestarted = Get-Service -ComputerName $hst.ComputerName -Name WinRM -ErrorAction SilentlyContinue | where {$_.Status -eq "Running"} 
                if ($winrmservicestarted) {
                    Write-Host $hst.ComputerName "ready"
                    $ready = 1
                }
                else {
                    Write-Host $hst.ComputerName "not ready, WinRM service not started"
                }
            }
            else {
                Write-Host $hst.ComputerName "Not ready, Network communication not restored"
                Start-Sleep -Seconds 5
            }
        }
    }
}
Function checkDBs
{
    foreach($hst in $HostConf)
    {
        Write-Host "Checking DBs on $($hst.ComputerName)"
        $SQLexists = Get-Service -ComputerName $hst.ComputerName -Name "MSSQLSERVER" -ErrorAction SilentlyContinue
        if($SQLexists)
        {
            [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO') | out-null
            $s = New-Object ('Microsoft.SqlServer.Management.Smo.Server') $hst.ComputerName
            $dbs=$s.Databases
            foreach($db in $dbs)
            {
                $advfuncExists = Invoke-Sqlcmd -Database $db.Name -ServerInstance $db.Parent`
                              -Query "select * from sys.objects where type = 'FN' AND name = 'fn_DBversion' AND schema_id = 1"
                $ezpfuncExists = Invoke-Sqlcmd -Database $db.Name -ServerInstance $db.Parent`
                              -Query "select * from sys.objects where type = 'FN' AND name = 'fn_DBversion' AND schema_id = 5"
                $versionsTableExists = Invoke-Sqlcmd -Database $db.Name -ServerInstance $db.Parent`
                              -Query "select 1 from INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'IGT_Versions'"
                if($ezpfuncExists)
                {
                    Write-Host "checking ezpay fn_DBversion"
                    $dbVersion = Invoke-Sqlcmd -Query "select VersionDbSchema.fn_DBVersion()" -Database $db.Name -ServerInstance $db.Parent
                    $out = New-Object psobject
                    $out | Add-Member noteproperty Server $hst.ComputerName
                    $out | Add-Member noteproperty DBname $db.Name
                    $out | Add-Member noteproperty DBversion $dbVersion[0]
                    $DBstatus += $out
                }
                if($versionsTableExists)
                {
                    Write-Host "checking IGT_Versions for $($db.Name)"
                    #The IGT_Versions table for TM is in the TMS schema
                    if($db.Name -eq 'tm')
                    {
                        $versionRows = Invoke-Sqlcmd -Query "select TOP 1 * from TMS.IGT_Versions where PackageID <> 'Seed' order by InstallationDate desc" -Database $db.Name -ServerInstance $db.Parent
                    }
                    else
                    {
                        $versionRows = Invoke-Sqlcmd -Query "WITH newestInstalls (Pname, Pdate) AS
                                                            (
                                                                SELECT ProductName, MAX(InstallationDate) 
                                                                FROM IGT_Versions
                                                                GROUP BY ProductName
                                                            )
                                                            SELECT * FROM IGT_Versions igtv
                                                            INNER JOIN newestInstalls ni ON
                                                            igtv.InstallationDate = ni.Pdate AND
                                                            igtv.ProductName = ni.Pname
                                                            where igtv.PackageID <> 'Seed'" -Database $db.Name -ServerInstance $db.Parent
                    }
                    foreach($versionRow in $versionRows)
                    {                    
                        $out = New-Object psobject
                        $out | Add-Member noteproperty Server $hst.ComputerName
                        $out | Add-Member noteproperty HostDBname $db.Name
                        $out | Add-Member noteproperty DBname $versionRow.ProductName
                        $out | Add-Member noteproperty DBversion $versionRow.Version
                        $DBstatus += $out
                    }
                }
                elseif($advfuncExists)
                {
                    Write-Host "checking fn_DBversion"
                    $dbVersion = Invoke-Sqlcmd -Query "select dbo.fn_DBVersion()" -Database $db.Name -ServerInstance $db.Parent
                    $out = New-Object psobject
                    $out | Add-Member noteproperty Server $hst.ComputerName
                    $out | Add-Member noteproperty DBname $db.Name
                    $out | Add-Member noteproperty DBversion $dbVersion[0]
                    $DBstatus += $out
                }
            }
        }
        else
        {
            Write-Host "SQL not found on $($hst.ComputerName)"
        }
    }
    return($DBstatus)
}
Function IGTDBStatus
{
    $dbStatus2 = @()
    $dbsOOS = @("RNGLOGDATABASE","VirtualDrawing","SBDB","Table Manager")
    foreach($db in $dbsRequired)
    {
        #search installed DBs for each required DB
        $finddb = $dbcheck|ForEach-Object{$_.DBName}|Where-Object{$_ -contains $db}
        $dbLoc = ($dbcheck | Where-Object {$_.DBName -eq $db}).Server
        $dbVersion = ($dbcheck | Where-Object {$_.DBName -eq $db}).DBVersion
        $out = New-Object psobject
        if($finddb)
        {
            $found = "DB Found"
            if($dbsOOS -contains $db)
            {
                $vsn = $dbVersion
                $PF = "Out of Scope"
            }
            else
            {
                if($dbVersion -eq $BNcompare)
                {
                    $vsn = $dbVersion
                    $PF = "Pass"
                }
                else
                {
                    $vsn = "Version mismatch: $dbVersion"
                    $PF = "Warning"
                }
            }
        }else
        {
            $found ="DB or Version NOT Found"
            if($db -eq "SBDB"){$PF = "Out of Scope"}
            else{$PF = "Fail"}
        }
        $out | Add-Member noteproperty DBName $db
        $out | Add-Member noteproperty Check $found
        $out | Add-Member noteproperty Server $dbLoc
        $out | Add-Member noteproperty Version $vsn
        $out | Add-Member noteproperty Validation $PF
        $dbStatus2 += $out
    }
    return($dbStatus2)
}
function Insert-Info
{
    param($Ftype,$Fproduct,$Fcheck,$Fstatus,$Fserver,$Fversion,$Fvalidation)
    
    
    <#
    $SqlQuery = "Insert into BVTresults (type,product,[check],status,server,version,validation,buildnum) values ('$Ftype','$Fproduct','$Fcheck','$Fstatus','$Fserver','$Fversion','$Fvalidation','$BN')"
    $ConnectionString = "Server=10.222.5.43;Database=BVTPERF;User ID=sa;Password=123456"
    $Connection = new-object System.Data.SqlClient.SqlConnection  $ConnectionString
    $Connection.ConnectionString = $ConnectionString
    $Connection.Open()
    $Command = New-Object System.Data.SQLClient.SQLCommand
    $Command.Connection = $Connection
    Write-Output "trying $SqlQuery"
    $Command.CommandText = $SqlQuery
    $Reader = $Command.ExecuteReader()
    $Connection.Close() 
    #>
    
}


$BN = Get-Content .\buildnum.txt
$BNsplit = $BN.Split(".")
$BNcompare = $BNsplit[0][-1]+"."+$BNsplit[1]+"."+$BNsplit[2]+"."+$BNsplit[3].split("-")[0]
$ValidationLog = "c:\autoinstall\logs\validate.log"
$DBlist = ".\config\dblist.csv"
$APPlist = ".\config\applist.csv"
New-Item $ValidationLog -type file -force -WarningAction SilentlyContinue
New-Item $DBlist -type file -force -WarningAction SilentlyContinue
New-Item $APPlist -type file -force -WarningAction SilentlyContinue
$applicationsRequired = Get-Content .\config\IGTapplications.txt
$servicesRequired = Get-Content .\config\IGTservices.txt
$dbsRequired = Get-Content .\config\IGTDBs.txt
$HostConf = Import-Csv .\config\IPSremoteALL-BVT1.csv
$formatHTML = "<style>"
$formatHTML += "body { background-color:#EEEEEE; }"
$formatHTML += "body,table,td,th { font-family:Tahoma; color:Black; Font-Size:10pt }"
$formatHTML += "table {width:600}"
$formatHTML += "th { font-weight:bold; background-color:#CCCCCC; }"
$formatHTML += "td { background-color:white; }"
$formatHTML += "</style>"

chkVMs
#find products installed
Write-Host "Looking for installed apps"
$productsInstalled = @()
$productsInstalled += $HostConf|ForEach-Object{IGTapps($_.ComputerName)}
#create object that displays whether a required product is installed and which server it is installed on
Write-Host "Comparing apps installed to apps required list"
$IGTAppStatus = ""
$IGTAppStatus = IGTAppStatus 
$IGTAppStatus|foreach{Insert-Info "Application" "$($_.ProductName)" "$($_.Check)" "" "$($_.Server)" "$($_.Version)" "$($_.Validation)"}
$IGTAppStatus|ConvertTo-Csv > $APPlist
Write-Output "$(Get-Date -f G) Applications status"$IGTAppStatus >> $Validationlog
$t = $IGTAppStatus | ConvertTo-Html -Title "Application Validation Status" -Head $formatHTML
$t = $t|ForEach-Object{$_ -replace "<td>Fail</td>","<td><b>Fail</b></td>"}
#services section
Write-Host "Getting Service Statuses"
$IGTServiceStatus = ""
$IGTServiceStatus = IGTServiceStatus 
"`n" >> $ValidationLog
Write-Output "$(Get-Date -f G) Services status"$IGTServiceStatus >> $Validationlog
#set service startup type to Automatic
Write-Host "Setting service startup types to Automatic"
$IGTServiceStatus|ForEach-Object{if($_.Server){Set-Service -Name $_.ServiceName -ComputerName $_.Server -StartupType Automatic}}
#start services 
Write-Host "Starting required services"
$IGTServiceStatus | ForEach-Object `
             {`
                if($_.server)`
                {`
                    (Get-WmiObject Win32_Service -ComputerName $_.server -Filter "Name = '$($_.ServiceName)'").InvokeMethod("StartService",$null)`
                }`
             }
#services that didn't start 
Write-Host "Waiting 60 seconds for services to finish starting"
sleep -Seconds 60
Write-Host "Checking for services that haven't started"
$svcNotStarted = ""
$svcsNotStarted = $IGTServiceStatus|ForEach-Object{if($_.server){Get-WmiObject -Query "SELECT * FROM Win32_Service where State <> ""Running"" AND Name = ""$($_.ServiceName)""" -ComputerName $_.server}}
$svcsNotStarted >> $ValidationLog
Write-Output "$(Get-Date -f G) Services that were not started" >> $Validationlog
$svcsNotStarted|ForEach-Object{Write-Output "$(Get-Date -f G) the $($_.Name) service did NOT start"} >> $Validationlog
#get services again after trying to start them all
$IGTServiceStatus = ""
$IGTServiceStatus = IGTServiceStatus 
$IGTServiceStatus|foreach{Insert-Info "Service" "$($_.ServiceName)" "$($_.Check)" "$($_.Status)" "$($_.Server)" "" "$($_.Validation)"}
$u = $IGTServiceStatus | ConvertTo-Html -Title "IGT Services Status"
$u = $u|ForEach-Object{$_ -replace "<td>Stopped</td>","<td><b>Stopped</b></td>"}
$u = $u|ForEach-Object{$_ -replace "<td>Fail</td>","<td><b>Fail</b></td>"}
$w = $svcsNotStarted|ForEach-Object{Write-Output "<br />$(Get-Date -f G) the $($_.Name) service did NOT start"}
#SQL
Add-PSSnapin SqlServerCmdletSnapin100 -ErrorAction SilentlyContinue
Write-Host "Checking Databases"
$DBstatus = @()
$DBcheck = checkDBs
$DBcheck|ConvertTo-Csv > $DBlist
$DBcompare = IGTDBstatus
"`n" >> $ValidationLog
Write-Output "$(Get-Date -f G) Database status"$DBcheck >> $Validationlog
$DBcompare|foreach{Insert-Info "Database" "$($_.DBName)" "$($_.Check)" "" "$($_.Server)" "$($_.Version)" "$($_.Validation)"}
$v = $DBcompare | ConvertTo-Html -Title "Databases Installed"
$v = $v|ForEach-Object{$_ -replace "<td>Fail</td>","<td><b>Fail</b></td>"}
#$newestErrorLog = (dir c:\autoinstall\logs\*\*\errors.log | Sort-Object LastWriteTime | Select-Object -Last 1).FullName
#$x = Get-Content $newestErrorLog|ForEach-Object{Write-Output "<br /> $_"}
$mailContent = $t + "<br />" + $u + "<br />" + $v + "<br />" + $w + "<br />" #+ $x
#.\mail.ps1 -subject "EGS BVT Validation Results" -content "Build Number $BN"  -attach "$ValidationLog"
c:\autoinstall\mail.ps1 -subject "Installation Validation Results for $BN" -content $mailContent
