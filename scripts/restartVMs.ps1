param($Param_VMlist)

$masterLog = ".\masterlog.log"

#insert script start date into log
Write-Host `
"#------------------------------------------------
#restartVMs.ps1 started: $(Get-Date -f G)      
#------------------------------------------------" >> $masterLog

$Param_VMlist|ForEach-Object{if($_){

                                      $restartResult = Restart-VMGuest -VM $_
                                      if(-not $restartResult){
                                        Restart-VM -VM $_ -Confirm:$false
                                        Write-Host "Force reboot the failed VM!"
                                      }
                                      else{
                                        Write-Host "$(Get-Date -f G)`tGuest restart command sent to $_" 
                                      }
                                      
                                  
                                   }
                            }
                            
                            
                          
