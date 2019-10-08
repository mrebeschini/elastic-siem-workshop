$StackVersion = '7.4.0'
$InstallFolder = "C:\Program Files\Elastic"
$ConfigRepositoryURL = "https://raw.githubusercontent.com/mrebeschini/elastic-siem-workshop/master/"

$CloudID = Read-Host -Prompt "Enter your Elastic Cloud CLOUD_ID then press [ENTER]"
if (!$CloudID) {
    Write-Host "Error: CLOUD_ID must be set to a non-empty value!"
    Exit
}
Write-Host "Your CLOUD_ID is set to: $CloudID`n"

$CloudAuth = Read-Host -Prompt 'Enter you Elastic Cloud ''elastic'' user password and then press [ENTER]'
if (!$CloudID) {
    Write-Host "Error: Your ''elastic'' user password must be set to a non-empty value!"
    Exit
}
Write-Host "You elastic password is set to: $CloudAuth`n"

$Continue = Read-Host -Prompt 'Ready to Install? [Y|N]'
if (!($Continue -ieq 'Y'))
{
    Write-Output "Installation aborted"
    Exit
}
Write-Output "Elastic Beats $StackVersion Installation Initiated"

function InstallElasticBeat ([string]$BeatName)
{
    $ArtifactURI = "https://artifacts.elastic.co/downloads/beats/$BeatName/$BeatName-" + $StackVersion + "-windows-x86_64.zip"
    $LocalFilePath = "C:\Windows\Temp\$BeatName.zip"
    $BeatInstallFolder = $InstallFolder + '\' + "$BeatName"

    Write-Host "`nInstalling $BeatName..."

    #If Beat was already installed, disinstall service and cleanup first

    if (Get-Service $BeatName -ErrorAction SilentlyContinue) {
        $service = Get-WmiObject -Class Win32_Service -Filter "name='$BeatName'"
        $service.StopService()
        Start-Sleep -s 1
        $service.delete()
    }
    if (Test-Path $BeatInstallFolder) {
        Remove-Item -Path $BeatInstallFolder -Recurse -Force
    }

    #Downloading Beat artifact and install it
    Write-Host "Downloading $BeatName artifact..."
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $ArtifactURI -OutFile $LocalFilePath
    Expand-Archive -Path $LocalFilePath -DestinationPath $InstallFolder
    Rename-Item -Path "$InstallFolder\$BeatName-$StackVersion-windows-x86_64" -NewName $BeatInstallFolder
    Remove-Item -Path $LocalFilePath

    #Update Beat configuration using workshop template and add Elastic Cloud cluster information to it (CloudId)
    Write-Host "Updating $BeatName.yml..."
    Rename-Item -Path $BeatInstallFolder\$BeatName.yml -NewName $BeatInstallFolder\$BeatName.yml.bak
    Invoke-WebRequest -Uri $ConfigRepositoryURL/$BeatName.yml -OutFile $BeatInstallFolder\$BeatName.yml

    #Create Beat keystore and add CLOUD_AUTH and CLOUD_ID secrets
    Push-Location $BeatInstallFolder
    Write-Host "Creating $BeatName keystore..."
    $params = $('keystore','create','--force')
    & .\$BeatName.exe $params
    Write-Host "Adding CLOUD_ID to $BeatName keystore..."
    $params = $('keystore','add','CLOUD_ID','--stdin','--force')
    Write-Output $CloudID | & .\$BeatName.exe $params
    Write-Host "Adding CLOUD_AUTH to $BeatName keystore..."
    $params = $('keystore','add','CLOUD_AUTH','--stdin','--force')
    Write-Output $CloudAuth | & .\$BeatName.exe $params
    Write-Host "Setting up Beat Modules..."
    $params = $('setup')
    & .\$BeatName.exe $params
    Write-Host "Testing $BeatName Connectivity to Elastic Cloud..."
    $params = $('test', 'output')
    & .\$BeatName.exe $params
    Pop-Location

    #Create Windows Service for Beat and start service
    Write-Host "Creating $BeatName service..."
    New-Service -name $BeatName `
                -displayName $BeatName `
                -binaryPathName "`"$BeatInstallFolder\$BeatName.exe`" -c `"$BeatInstallFolder\$BeatName.yml`" -path.home `"$BeatInstallFolder`"" `
                -startupType Automatic
    Write-Host "Starting $BeatName service..."
    Start-Service -Name "$BeatName"
    Write-Host "`n$BeatName Installation Completed!`n"
}

InstallElasticBeat("winlogbeat")
InstallElasticBeat("metricbeat")
