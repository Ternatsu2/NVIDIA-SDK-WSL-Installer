<#
.SYNOPSIS
  Main Installer script for importing a WSL distro (Ubuntu-22.04) and installing NVIDIA SDK Manager.

.DESCRIPTION
  1. Progress bar steps for user visibility.
  2. Imports a tar file to create a new WSL distro under a custom name.
  3. Installs Google Chrome and SDK Manager dependencies inside WSL.
  4. Launches SDK Manager automatically.
  5. Waits for user input at the end so the console doesn’t disappear.
#>

# Initialize progress tracking (if you still want minimal progress, you can remove or simplify)
$StepsTotal = 6
$StepCurrent = 0
function Update-Progress {
    param(
        [int]$Current,
        [int]$Total,
        [string]$Activity,
        [string]$Status
    )
    Write-Progress -Activity $Activity -Status $Status -PercentComplete (($Current / $Total) * 100)
}

# Step 1: Define variables
$StepCurrent++
Update-Progress -Current $StepCurrent -Total $StepsTotal -Activity "WSL Setup" -Status "Checking for SDK Manager..."

$DistroName = "Ubuntu-22.04-NVIDIA"  # <--- Custom name to avoid conflicts
$UserHomePath = [Environment]::GetFolderPath("UserProfile")
$DownloadPath = Join-Path $UserHomePath "Downloads"
$DistroTar = Join-Path $DownloadPath "ubuntu-22.04.tar"

# Locate SDK Manager .deb
$SdkManagerDeb = Get-ChildItem -Path $DownloadPath -Filter "sdkmanager_*.deb" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if (-not $SdkManagerDeb) {
    Write-Host "SDK Manager .deb file not found in $DownloadPath. Please place the file there and re-run."
    Write-Host "Press Enter to exit..."
    [void][System.Console]::ReadLine()
    exit 1
}

# Step 2: Import a fresh distro every time
$StepCurrent++
Update-Progress -Current $StepCurrent -Total $StepsTotal -Activity "WSL Setup" -Status "Importing new $DistroName distro..."

Set-Location $DownloadPath
if (-not (Test-Path $DistroTar)) {
    Write-Host "Distro tar file not found at $DistroTar. Please place ubuntu-22.04.tar in $DownloadPath."
    Write-Host "Press Enter to exit..."
    [void][System.Console]::ReadLine()
    exit 1
}

Write-Host "$DistroName will be installed as a new WSL distro (no conflict with existing Ubuntus)."
$DistroInstallPath = "C:\WSL\$DistroName"
if (-not (Test-Path $DistroInstallPath)) {
    New-Item -ItemType Directory -Path $DistroInstallPath | Out-Null
}

Write-Host "Running: wsl --import $DistroName $DistroInstallPath .\ubuntu-22.04.tar --version 2"
wsl --import $DistroName $DistroInstallPath .\ubuntu-22.04.tar --version 2
Write-Host "wsl --import exit code = $LastExitCode"

if ($LastExitCode -ne 0) {
    Write-Host "Failed to import $DistroName. Check if you have Admin rights or if your Windows version supports WSL."
    Write-Host "Press Enter to exit..."
    [void][System.Console]::ReadLine()
    exit 1
} else {
    Write-Host "$DistroName imported successfully."
}

# Step 3: Verify the new distro
$StepCurrent++
Update-Progress -Current $StepCurrent -Total $StepsTotal -Activity "WSL Setup" -Status "Verifying new distro registration..."

$installedDistros = wsl --list --quiet
Write-Host "wsl --list --quiet exit code = $LastExitCode"
if ($installedDistros -notcontains $DistroName) {
    Write-Host "Distro $DistroName not found after import. Something went wrong."
    Write-Host "Press Enter to exit..."
    [void][System.Console]::ReadLine()
    exit 1
} else {
    Write-Host "$DistroName is registered and ready."
}

# Step 4: Prepare for SDK Manager setup
$StepCurrent++
Update-Progress -Current $StepCurrent -Total $StepsTotal -Activity "WSL Setup" -Status "Preparing SDK Manager installation..."

$SdkManagerPath = "/mnt/" + $SdkManagerDeb.DirectoryName.Substring(0,1).ToLower() + "/" + $SdkManagerDeb.DirectoryName.Substring(3).Replace("\","/") + "/" + $SdkManagerDeb.Name
Write-Host "Found SDK Manager file: $SdkManagerPath"

Write-Host "Setting up $DistroName and installing required packages..."

# Step 5: Build the command array
$StepCurrent++
Update-Progress -Current $StepCurrent -Total $StepsTotal -Activity "WSL Setup" -Status "Installing dependencies & SDK Manager..."

$Commands = @(
    "export DEBIAN_FRONTEND=noninteractive",
    "sudo apt-get update -y",
    "sudo apt-get install -y wget libnss3 libgbm1 libcanberra-gtk-module libcanberra-gtk3-module 2>/dev/null",
    # Quiet mode for wget to avoid spam
    "wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb",
    "sudo apt-get install -y ./google-chrome-stable_current_amd64.deb 2>/dev/null",
    "sudo dpkg -i $SdkManagerPath 2>/dev/null",
    "sudo apt --fix-broken install -y 2>/dev/null",
    "echo 'Installation complete. Launching SDK Manager...'",
    # Autoconfirm sdkmanager prompt
    "echo y | sdkmanager"
)

$CommandString = $Commands -join " && "
Write-Host "Executing inside WSL: $CommandString"
wsl -d $DistroName -- bash -c "$CommandString"
Write-Host "Inside WSL apt & dpkg exit code = $LastExitCode"

# Step 6: Final wrap-up
$StepCurrent++
Update-Progress -Current $StepCurrent -Total $StepsTotal -Activity "WSL Setup" -Status "Completing setup..."

Write-Progress -Activity "WSL Setup" -Status "Finished!" -Completed

Write-Host "Process completed (or attempted) successfully. $DistroName is now installed!"
Write-Host "Press Enter to exit..."
[void][System.Console]::ReadLine()
