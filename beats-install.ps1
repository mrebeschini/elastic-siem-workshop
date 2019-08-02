$StackVersion = '7.3.0'
$InstallFolder = "C:\Program Files\Elastic"
$ConfigRepositoryURL = "https://raw.githubusercontent.com/mrebeschini/2019BSidesLV/master/"

$CloudID = Read-Host -Prompt "Enter your Elastic Cloud CLOUD_ID then press [ENTER]"
Write-Host "Your CLOUD_ID is set to: $CloudID`n"

$CloudAuth = Read-Host -Prompt 'Enter you Elastic Cloud ''elastic'' user password and then press [ENTER]'
Write-Host "You elastic password is set to: $CloudAuth`n"

$Continue = Read-Host -Prompt 'Ready to Install? [Y|N]'
if (!($Continue -ieq 'Y'))
{
    Write-Output "Installation aborted"
    Exit
}
Write-Output "Elastic Beats Installation Initiated"

function InstallElasticBeat ([string]$BeatName)
{
    $ArtifactURI = "https://artifacts.elastic.co/downloads/beats/$BeatName/$BeatName-" + $StackVersion + "-windows-x86_64.zip"
    $LocalFilePath = "C:\Windows\Temp\$BeatName.zip"
    $BeatInstallFolder = $InstallFolder + '\' + "$BeatName"
    
    Write-Host "`nInstalling $BeatName..."
    
    #If Beat was already installed, disinstall service and cleanup first
    if (Test-Path $BeatInstallFolder) {
        Stop-Service -Name $BeatName
        & "$BeatInstallFolder\uninstall-service-$BeatName.ps1"
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
    Write-Host "Testing Beat Connectivity to Elastic Cloud..."
    $params = $('test', 'output')
    & .\$BeatName.exe $params
    
    Pop-Location

    #Create Windows Service for Beat and start service
    Write-Host "Creating $BeatName service..."
    & $BeatInstallFolder\\install-service-$BeatName.ps1
    Write-Host "Starting $BeatName service..."
    Start-Service -Name "$BeatName"
    Write-Host "$BeatName Installation Completed!"
    
}

InstallElasticBeat("winlogbeat")
InstallElasticBeat("metricbeat")
