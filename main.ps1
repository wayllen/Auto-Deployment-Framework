 #Define type.
$BuildType = "Man"

 #Define folder location.
$BuildFolder = "\\10.175.8.253\Build\9.2\main\"

 #Define upgrade type.
$Upgrade = 1

  #Start
& .\MasterScript.ps1 $BuildType $BuildFolder $Upgrade
