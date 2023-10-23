$PrimaryAdapter = "Wi-Fi"
$SecondaryAdapter = "Ethernet"
$RemoteHostName = "www.google.com"
$LogFilePath = "logs.txt"
$PrimaryRevertMins = "5" # In minutes

# Log entry for script initialization
"$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Script initialized" | Out-File -FilePath $LogFilePath -Append

# Functions
function Get-AdapterStatus { param([string]$adapter_name) (Get-NetAdapter -Name $adapter_name).status}
function Enable-Adapter { param ([string]$adapter_name) Enable-NetAdapter -Name $adapter_name -Confirm:$false}
function Disable-Adapter { param ([string]$adapter_name) Disable-NetAdapter -Name $adapter_name -Confirm:$false}
function Test-RemoteHostReach { Test-Connection -ComputerName $RemoteHostName -Count 1 -Quiet }


while ($True){
    $PrimaryStatus = Get-AdapterStatus -adapter_name $PrimaryAdapter
    $SecondaryStatus = Get-AdapterStatus -adapter_name $SecondaryAdapter
    if ($PrimaryStatus -eq "Disconnected" -or $PrimaryStatus -eq "Up"){
        Write-Output "Primary adapter is enabled...testing connection"
        "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Primary adapter is enabled...testing connection" | Out-File -FilePath $LogFilePath -Append
        while ($True){
            if (Test-RemoteHostReach){
                Write-Output "Connection test passed...sleeping"
                "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Connection test passed...sleeping" | Out-File -FilePath $LogFilePath -Append
                Start-Sleep -Seconds 5
            }else{
                Write-Output "Connection test failed...enabling secondary adapter"
                "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Connection test failed...enabling secondary adapter" | Out-File -FilePath $LogFilePath -Append
                Disable-Adapter -adapter_name $PrimaryAdapter
                Enable-Adapter -adapter_name $SecondaryAdapter
                Start-Sleep -Seconds 5
                break
            }
        }
    }else{
        Write-Output "Secondary adapter is up...testing connection"
        "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Secondary adapter is up...testing connection" | Out-File -FilePath $LogFilePath -Append
        $SecondaryUpTime = $(Get-Date)
        while ($True){
            if (Test-RemoteHostReach){
                Write-Output "Connection test passed...sleeping"
                "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Connection test passed...sleeping" | Out-File -FilePath $LogFilePath -Append
                $CurrentTime = $(Get-Date)
                $TimeElapsed = [math]::Round(($CurrentTime - $SecondaryUpTime).TotalMinutes)
                if ($TimeElapsed -eq $PrimaryRevertMins){
                    Write-Output "5 minutes since on secondary adapter...attempting revert to primary"
                    "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - 5 minutes since on secondary adapter...attempting revert to primary" | Out-File -FilePath $LogFilePath -Append
                    Disable-Adapter -adapter_name $SecondaryAdapter
                    Enable-Adapter -adapter_name $PrimaryAdapter
                    Start-Sleep -Seconds 5
                    if(Test-RemoteHostReach){
                        Write-Output "Connection test passed...primary adapter restored"
                        "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Connection test passed...primary adapter restored" | Out-File -FilePath $LogFilePath -Append
                        break
                    } else { 
                        Write-Output "Connection test failed...continuing on secondary adapter"
                        "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Connection test failed...continuing on secondary adapter" | Out-File -FilePath $LogFilePath -Append
                        continue
                    }
                }
                Start-Sleep -Seconds 5
            }else{
                Write-Output "Connection test failed...reverting to primary adapter"
                "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Connection test failed...reverting to primary adapter" | Out-File -FilePath $LogFilePath -Append
                Disable-Adapter -adapter_name $SecondaryAdapter
                Enable-Adapter -adapter_name $PrimaryAdapter
                Start-Sleep -Seconds 5
                break
            }
        }
    }
}
