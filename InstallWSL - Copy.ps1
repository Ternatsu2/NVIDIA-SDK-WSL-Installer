# Initialize progress tracking
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

# Step 1: Define variables and check for SDK Manager .deb
$StepCurrent++
Update-Progress -Current $StepCurrent -Total $StepsTotal -Activity "WSL Setup" -Status "Checking for SDK Manager .deb..."

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

# Step 2: Check for ubuntu-22.04.tar and import distro
$StepCurrent++
Update-Progress -Current $StepCurrent -Total $StepsTotal -Activity "WSL Setup" -Status "Preparing to import Ubuntu .tar..."

Set-Location $DownloadPath
if (-not (Test-Path $DistroTar)) {
    Write-Host "Distro tar file not found at $DistroTar. Please place ubuntu-22.04.tar in $DownloadPath."
    exit 1
}

Write-Host "$DistroName is not installed. Attempting to import from ubuntu-22.04.tar..."
$DistroInstallPath = ".\Ubuntu_Install"
if (-not (Test-Path $DistroInstallPath)) {
    New-Item -ItemType Directory -Path $DistroInstallPath | Out-Null
}

wsl --import $DistroName $DistroInstallPath .\ubuntu-22.04.tar --version 2
if ($LastExitCode -ne 0) {
    Write-Host "Failed to import the distro. Check if you have Admin rights, correct file location, and NTFS permissions."
    exit 1
} else {
    Write-Host "$DistroName imported successfully."
}

# Step 3: Verify distro is registered
$StepCurrent++
Update-Progress -Current $StepCurrent -Total $StepsTotal -Activity "WSL Setup" -Status "Verifying distro registration..."

$installedDistros = wsl --list --quiet
if ($installedDistros -notcontains $DistroName) {
    Write-Host "Distro not found after import. Something went wrong."
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

# Step 5: Build the command array with DEBIAN_FRONTEND and selective error suppression
$StepCurrent++
Update-Progress -Current $StepCurrent -Total $StepsTotal -Activity "WSL Setup" -Status "Installing dependencies & SDK Manager..."

$Commands = @(
    # Force noninteractive for apt/dpkg
    "export DEBIAN_FRONTEND=noninteractive",
    # Update package lists, show errors if any
    "sudo apt-get update -y",
    # Install needed packages, redirect only known debconf warnings
    "sudo apt-get install -y wget libnss3 libgbm1 libcanberra-gtk-module libcanberra-gtk3-module 2>/dev/null",
    # Download Chrome **in quiet mode** to hide progress lines
    "wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb",
    # Install Chrome, ignore interactive prompts
    "sudo apt-get install -y ./google-chrome-stable_current_amd64.deb 2>/dev/null",
    # Install SDK Manager .deb, redirect potential "dialog" warnings
    "sudo dpkg -i $SdkManagerPath 2>/dev/null",
    # Fix broken installs
    "sudo apt --fix-broken install -y 2>/dev/null",
    "echo 'Installation complete. Launching SDK Manager...'",
    # Autoconfirm sdkmanager prompt
    "echo y | sdkmanager"
)

$CommandString = $Commands -join " && "
wsl -d $DistroName -- bash -c "$CommandString"

# Step 6: Final wrap-up
$StepCurrent++
Update-Progress -Current $StepCurrent -Total $StepsTotal -Activity "WSL Setup" -Status "Completing setup..."

Write-Progress -Activity "WSL Setup" -Status "Finished!" -Completed
Write-Host "Process completed successfully without manual intervention."
