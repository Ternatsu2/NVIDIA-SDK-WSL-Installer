# Variables
$DistroName = "Ubuntu-22.04"
$UserHomePath = [Environment]::GetFolderPath("UserProfile")
$DownloadPath = Join-Path $UserHomePath "Downloads"
$DistroTar = Join-Path $DownloadPath "ubuntu-22.04.tar"

# Locate SDK Manager .deb
$SdkManagerDeb = Get-ChildItem -Path $DownloadPath -Filter "sdkmanager_*.deb" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if (-not $SdkManagerDeb) {
    Write-Host "SDK Manager .deb file not found in $DownloadPath. Please place the file there and re-run."
    exit 1
}

# Change to the Downloads directory so we can use relative paths
Set-Location $DownloadPath

if (-not (Test-Path $DistroTar)) {
    Write-Host "Distro tar file not found at $DistroTar. Please place ubuntu-22.04.tar in $DownloadPath."
    exit 1
}

Write-Host "$DistroName is not installed. Attempting to import from ubuntu-22.04.tar..."

# Create a local directory inside Downloads for the WSL distro
# Using a relative path to avoid absolute path issues.
$DistroInstallPath = ".\Ubuntu_Install"
if (-not (Test-Path $DistroInstallPath)) {
    New-Item -ItemType Directory -Path $DistroInstallPath | Out-Null
}

# Use relative paths for import
# ./ubuntu-22.04.tar should be accessible now since we are in $DownloadPath
wsl --import $DistroName $DistroInstallPath .\ubuntu-22.04.tar --version 2
if ($LastExitCode -ne 0) {
    Write-Host "Failed to import the distro. Check if you have Admin rights, correct file location, and NTFS permissions."
    exit 1
} else {
    Write-Host "$DistroName imported successfully."
}

# After import, distro should be registered
$installedDistros = wsl --list --quiet
if ($installedDistros -notcontains $DistroName) {
    Write-Host "Distro not found after import. Something went wrong."
    exit 1
} else {
    Write-Host "$DistroName is registered and ready."
}

# Find SDK Manager file path in WSL format
$SdkManagerPath = "/mnt/" + $SdkManagerDeb.DirectoryName.Substring(0,1).ToLower() + "/" + $SdkManagerDeb.DirectoryName.Substring(3).Replace("\","/") + "/" + $SdkManagerDeb.Name
Write-Host "Found SDK Manager file: $SdkManagerPath"

Write-Host "Setting up $DistroName and installing required packages..."

$Commands = @(
    "sudo apt-get update -y",
    "sudo apt-get install -y wget libnss3 libgbm1 libcanberra-gtk-module libcanberra-gtk3-module",
    "wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb",
    "sudo apt-get install -y ./google-chrome-stable_current_amd64.deb",
    "sudo dpkg -i $SdkManagerPath",
    "sudo apt --fix-broken install -y",
    "echo 'Installation complete. Launching SDK Manager...'",
    # Here we pipe 'y' into sdkmanager to auto-accept.
    "echo y | sdkmanager"
)

$CommandString = $Commands -join " && "
wsl -d $DistroName -- bash -c "$CommandString"
Write-Host "Process completed successfully without manual intervention."
