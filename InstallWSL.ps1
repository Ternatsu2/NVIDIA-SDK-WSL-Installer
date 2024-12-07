# Functions
function Check-WSLEngine {
    Write-Host "Checking for WSL installation..."
    if (-not (Get-WindowsOptionalFeature -Online | Where-Object { $_.FeatureName -eq "Microsoft-Windows-Subsystem-Linux" }).State -eq "Enabled") {
        Write-Host "WSL is not installed. Installing WSL..."
        Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart
        Write-Host "WSL installed successfully. Please restart your computer and re-run the script."
        exit
    } else {
        Write-Host "WSL is already installed."
    }
}

function Get-UbuntuVersion {
    Write-Host "Which version of Ubuntu would you like to install?"
    Write-Host "1. Ubuntu 22.04"
    Write-Host "2. Ubuntu 24.04"
    $choice = Read-Host "Enter 1 or 2"
    if ($choice -eq "1") {
        return "Ubuntu-22.04"
    } elseif ($choice -eq "2") {
        return "Ubuntu-24.04"
    } else {
        Write-Host "Invalid choice. Defaulting to Ubuntu 22.04."
        return "Ubuntu-22.04"
    }
}

# User Path Setup
$UserHomePath = [System.Environment]::GetFolderPath("UserProfile")
$DownloadPath = Join-Path -Path $UserHomePath -ChildPath "Downloads"
$LinuxDownloadPath = "/mnt/" + $DownloadPath.Replace("C:\", "c/").Replace("\", "/")

# Check WSL Engine
Check-WSLEngine

# Ubuntu Version Selection
$DistroName = Get-UbuntuVersion

# Prompt for SDK Manager .deb File
Write-Host "Please download NVIDIA SDK Manager from https://developer.nvidia.com/nvidia-sdk-manager and place it in $DownloadPath."
Read-Host -Prompt "Press Enter to continue after placing the SDK Manager in the specified folder"

# Find SDK Manager File
$sdkmanagerFiles = Get-ChildItem -Path $DownloadPath -Filter "sdkmanager_*.deb" | Sort-Object LastWriteTime -Descending | Select-Object -First 1

if ($sdkmanagerFiles) {
    $sdkmanagerFilePath = "$LinuxDownloadPath/$($sdkmanagerFiles.Name)"
    Write-Host "Found SDK Manager file: $sdkmanagerFilePath"

    # Install WSL and Ubuntu
    Write-Host "Setting WSL to version 2..."
    wsl --set-default-version 2

    if (-not (wsl --list --installed | Select-String -Pattern $DistroName)) {
        wsl --install -d $DistroName
        Write-Host "$DistroName is now installed. Please complete the initial user setup."
        Read-Host -Prompt "Press Enter to continue after completing the setup in WSL"
    } else {
        Write-Host "$DistroName is already installed."
    }

    # Execute Linux Commands
    Write-Host "Setting up $DistroName and installing required packages..."
    $wslCommand = @"
sudo apt update &&
sudo apt install -y wget libnss3 libgbm1 &&
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb &&
sudo apt install -y ./google-chrome-stable_current_amd64.deb &&
sudo dpkg -i "$sdkmanagerFilePath" &&
sudo apt --fix-broken install &&
echo 'Installation complete. Launching SDK Manager...' &&
sdkmanager
"@
    wsl -d $DistroName -- bash -c "$wslCommand"
} else {
    Write-Host "SDK Manager .deb file not found in the Downloads directory. Please ensure the file is placed correctly."
}
