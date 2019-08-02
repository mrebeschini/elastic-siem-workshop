$SysmonURI = "https://download.sysinternals.com/files/Sysmon.zip"
$TempFolder = "C:\sysmon-temp"
$LocalFilePath = "$TempFolder\sysmon.zip"
$SysmonConfigFileURI = "https://raw.githubusercontent.com/olafhartong/sysmon-configs/master/sysmonconfig-v10.xml"
$LocalRulesFilePath = "C:\Windows\sysmon.xml"

if (Test-Path "C:\Windows\Sysmon64.exe")
{
    Write-Host "Unistalling Sysmon"
    Start-Process -WorkingDirectory "C:\Windows" -FilePath "sysmon64" -ArgumentList "-u" -Wait
}

Write-Host "Installing Sysmon..."
if (!(Test-Path $TempFolder)) {
    New-Item -Path $TempFolder -Type directory
}
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-WebRequest -Uri $SysmonConfigFileURI -OutFile $LocalRulesFilePath
Invoke-WebRequest -Uri $SysmonURI -OutFile $LocalFilePath
Expand-Archive -Path $LocalFilePath -DestinationPath $TempFolder
Start-Process -WorkingDirectory "$TempFolder" -FilePath "sysmon64" -ArgumentList "-accepteula -i $LocalRulesFilePath" -Wait
Remove-Item -Path $TempFolder -Recurse -Force
Write-Host "Installation Complete"
