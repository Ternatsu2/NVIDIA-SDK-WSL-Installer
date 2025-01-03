<#
.SYNOPSIS
  Main Installer script (with auto-unregister) for importing a WSL distro (Ubuntu-22.04-NVIDIA)
  and installing NVIDIA SDK Manager.

.DESCRIPTION
  1. Checks if the distro name already exists; if yes, unregisters it automatically.
  2. Imports the .tar to create a new WSL distro under a custom name.
  3. Installs Google Chrome and SDK Manager dependencies inside WSL.
  4. Launches SDK Manager automatically.
  5. Prints debug info and leaves the console open at the end.
#>

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

# Step 1: Define variables
$StepCurrent++
Update-Progress -Current $StepCurrent -Total $StepsTotal -Activity "WSL Setup" -Status "Preparing environment..."

$DistroName    = "Ubuntu-22.04-NVIDIA"  # <--- Custom name
$UserHomePath  = [Environment]::GetFolderPath("UserProfile")
$DownloadPath  = Join-Path $UserHomePath "Downloads"
$DistroTar     = Join-Path $DownloadPath "ubuntu-22.04.tar"

Write-Host "`nDEBUG: UserHomePath   = '$UserHomePath'"
Write-Host "DEBUG: DownloadPath    = '$DownloadPath'"
Write-Host "DEBUG: DistroTar       = '$DistroTar'"
Write-Host "DEBUG: (Test-Path $DistroTar) = " (Test-Path $DistroTar)

# Step 2: Unregister if distro already exists
$StepCurrent++
Update-Progress -Current $StepCurrent -Total $StepsTotal -Activity "WSL Setup" -Status "Checking for existing distro..."

$allDistros = wsl --list --quiet
if ($allDistros -contains $DistroName) {
    Write-Host "Distro '$DistroName' already exists. Unregistering to ensure a fresh setup..."
    wsl --unregister $DistroName
    Write-Host "Unregistered existing distro '$DistroName' successfully."
}

# Step 3: Verify we have the .tar and import
$StepCurrent++
Update-Progress -Current $StepCurrent -Total $StepsTotal -Activity "WSL Setup" -Status "Importing $DistroName..."

if (-not (Test-Path $DistroTar)) {
    Write-Host "`nDistro tar file not found at $DistroTar."
    Write-Host "Please place 'ubuntu-22.04.tar' in $DownloadPath."
    Write-Host "`nPress Enter to exit..."
    [void][System.Console]::ReadLine()
    exit 1
}

Write-Host "`nImporting $DistroName..."
$DistroInstallPath = "C:\WSL\$DistroName"
if (-not (Test-Path $DistroInstallPath)) {
    Write-Host "Creating directory '$DistroInstallPath' for the distro..."
    New-Item -ItemType Directory -Path $DistroInstallPath | Out-Null
}

Write-Host "`nRunning: wsl --import $DistroName $DistroInstallPath .\ubuntu-22.04.tar --version 2"
Set-Location $DownloadPath
wsl --import $DistroName $DistroInstallPath ".\ubuntu-22.04.tar" --version 2
Write-Host "DEBUG: wsl --import exit code = $LastExitCode"

if ($LastExitCode -ne 0) {
    Write-Host "Failed to import $DistroName. Check if you have Admin rights or if your Windows version supports WSL."
    Write-Host "`nPress Enter to exit..."
    [void][System.Console]::ReadLine()
    exit 1
} else {
    Write-Host "`n$DistroName imported successfully."
}

# Step 4: Verify the new distro
$StepCurrent++
Update-Progress -Current $StepCurrent -Total $StepsTotal -Activity "WSL Setup" -Status "Verifying new distro registration..."

$installedDistros = wsl --list --quiet
Write-Host "`nDEBUG: wsl --list --quiet returned:"
$installedDistros | ForEach-Object { Write-Host "   $_" }

if ($installedDistros -notcontains $DistroName) {
    Write-Host "Distro $DistroName not found after import. Something went wrong."
    Write-Host "`nPress Enter to exit..."
    [void][System.Console]::ReadLine()
    exit 1
} else {
    Write-Host "`n$DistroName is registered and ready."
}

# Step 5: Locate SDK Manager .deb & Install
$StepCurrent++
Update-Progress -Current $StepCurrent -Total $StepsTotal -Activity "WSL Setup" -Status "Preparing SDK Manager..."

$SdkManagerDeb = Get-ChildItem -Path $DownloadPath -Filter "sdkmanager_*.deb" -ErrorAction SilentlyContinue |
                 Sort-Object LastWriteTime -Descending | Select-Object -First 1
if (-not $SdkManagerDeb) {
    Write-Host "`nSDK Manager .deb file not found in $DownloadPath."
    Write-Host "Place the sdkmanager_*.deb file in your Downloads folder and re-run."
    Write-Host "`nPress Enter to exit..."
    [void][System.Console]::ReadLine()
    exit 1
}

$SdkManagerPath = "/mnt/" + $SdkManagerDeb.DirectoryName.Substring(0,1).ToLower() + "/" +
                  $SdkManagerDeb.DirectoryName.Substring(3).Replace("\","/") + "/" +
                  $SdkManagerDeb.Name

Write-Host "`nFound SDK Manager file: $SdkManagerPath"
Write-Host "`nSetting up $DistroName and installing required packages..."

# Step 6: Build commands to run inside WSL
$StepCurrent++
Update-Progress -Current $StepCurrent -Total $StepsTotal -Activity "WSL Setup" -Status "Installing dependencies & SDK..."

$Commands = @(
    "export DEBIAN_FRONTEND=noninteractive",
    "sudo apt-get update -y",
    "sudo apt-get install -y wget libnss3 libgbm1 libcanberra-gtk-module libcanberra-gtk3-module 2>/dev/null",
    "wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb",
    "sudo apt-get install -y ./google-chrome-stable_current_amd64.deb 2>/dev/null",
    "sudo dpkg -i $SdkManagerPath 2>/dev/null",
    "sudo apt --fix-broken install -y 2>/dev/null",
    "echo 'Installation complete. Launching SDK Manager...'",
    "echo y | sdkmanager"
)

$CommandString = $Commands -join " && "
Write-Host "`nDEBUG: Full WSL command string:"
Write-Host $CommandString

Write-Host "`nExecuting commands in WSL..."
Set-Location $DownloadPath
wsl -d $DistroName -- bash -c "$CommandString"
Write-Host "DEBUG: apt/dpkg/sdkmanager exit code = $LastExitCode"

Write-Progress -Activity "WSL Setup" -Status "Finished!" -Completed
Write-Host "`nProcess completed (or attempted) successfully. $DistroName is now installed!"

Write-Host "`nPress Enter to exit..."
[void][System.Console]::ReadLine()
