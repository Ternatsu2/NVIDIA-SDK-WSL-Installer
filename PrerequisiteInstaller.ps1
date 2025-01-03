<#
.SYNOPSIS
  Integrated Prerequisite Installer for WSL + Execution Policy Setup + Kernel MSI + Automatic wsl.exe --update.
  Ensures the system is ready for the Main Installer (Ubuntu import & NVIDIA SDK Manager).

.DESCRIPTION
  1. Checks for Admin privileges.
  2. Enables WSL optional features (Microsoft-Windows-Subsystem-Linux + VirtualMachinePlatform) using DISM.
  3. Downloads & installs the WSL kernel update MSI if not detected.
  4. Runs wsl.exe --update automatically (if supported).
  5. Sets WSL default version to 2.
  6. Sets PowerShell Execution Policy to allow remote scripts.
  7. Prompts for a reboot if needed (one reboot only).
  8. Does not auto-close; user presses Enter to exit.

.NOTES
  Author: [Your Name]
  Date: [Today]
#>

Write-Host "`n=== Prerequisite WSL Installer & Setup ===`n"

# STEP 1: Check Administrator Privileges
function Assert-Admin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    $isAdmin = $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        Write-Host "ERROR: Please run this script as Administrator. Exiting..."
        Write-Host "`nPress Enter to exit..."
        [void][System.Console]::ReadLine()
        exit 1
    }
}
Assert-Admin

# STEP 2: Global Variables
$Global:needsReboot = $false

# Variables for WSL Kernel MSI
$kernelInstallerName = "wsl_update_x64.msi"
$kernelUrl           = "https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi"
$kernelLocalPath     = "$env:USERPROFILE\Downloads\$kernelInstallerName"

# STEP 3: Enable WSL & VM Platform features using DISM
function Enable-WSLFeatures {
    Write-Host "Checking if WSL & VM Platform features are enabled..."

    $wslFeature = (Get-WindowsOptionalFeature -Online | Where-Object { $_.FeatureName -eq "Microsoft-Windows-Subsystem-Linux" })
    $vmFeature  = (Get-WindowsOptionalFeature -Online | Where-Object { $_.FeatureName -eq "VirtualMachinePlatform" })

    # If WSL not enabled
    if ($wslFeature.State -ne "Enabled") {
        Write-Host "Enabling Microsoft-Windows-Subsystem-Linux feature..."
        dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
        $Global:needsReboot = $true
    } else {
        Write-Host "WSL feature is already enabled."
    }

    # If Virtual Machine Platform not enabled
    if ($vmFeature.State -ne "Enabled") {
        Write-Host "Enabling VirtualMachinePlatform feature..."
        dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
        $Global:needsReboot = $true
    } else {
        Write-Host "Virtual Machine Platform is already enabled."
    }
}

Enable-WSLFeatures

# STEP 4: Install or Update WSL Kernel MSI if needed
function Install-KernelMSI {
    Write-Host "`nChecking for WSL 2 Kernel update..."

    $wslCheck = Get-Command wsl -ErrorAction SilentlyContinue
    $kernelInstalled = $false

    if (-not $wslCheck) {
        Write-Host "No 'wsl' command found. We'll install the kernel update package to be sure..."
        $kernelInstalled = $true
    } else {
        try {
            $versionResult = wsl --version 2>&1
            if ($versionResult -match "WSL version:" -or $versionResult -match "Windows Subsystem for Linux.*installed") {
                Write-Host "WSL found, but let's ensure the kernel is up to date..."
                $kernelInstalled = $true
            } else {
                Write-Host "WSL found, but exact version unclear. We'll install/update the kernel to be safe."
                $kernelInstalled = $true
            }
        }
        catch {
            Write-Host "WSL command not working properly. Let's install the kernel update."
            $kernelInstalled = $true
        }
    }

    if ($kernelInstalled) {
        Write-Host "Downloading or updating WSL2 kernel..."

        if (-not (Test-Path $kernelLocalPath)) {
            Write-Host "Downloading WSL kernel MSI to: $kernelLocalPath"
            Invoke-WebRequest -Uri $kernelUrl -OutFile $kernelLocalPath
        }
        else {
            Write-Host "Kernel MSI already in Downloads folder. Using $kernelLocalPath"
        }

        Write-Host "Installing WSL kernel update silently..."
        Start-Process msiexec.exe -ArgumentList "/i `"$kernelLocalPath`" /quiet /norestart" -Wait
        Write-Host "WSL kernel update installed."
        $Global:needsReboot = $true
    }
    else {
        Write-Host "It appears the WSL kernel is already present. Skipping MSI install."
    }
}

Install-KernelMSI

# STEP 5: Attempt wsl.exe --update (for Store-based WSL)
function Update-WSL {
    Write-Host "`nTrying wsl.exe --update (Store-based WSL support)..."

    $wslCheck = Get-Command wsl -ErrorAction SilentlyContinue
    if ($wslCheck) {
        try {
            Start-Process "wsl.exe" -ArgumentList "--update" -Wait -ErrorAction Stop
            Write-Host "wsl.exe --update completed (if it was needed)."
            $Global:needsReboot = $true
        }
        catch {
            Write-Host "wsl.exe --update failed or not supported. Error: $_"
            Write-Host "If the system is older (in-box WSL), this is normal. Continuing..."
        }
    }
    else {
        Write-Host "No 'wsl' command found at all, skipping wsl.exe --update."
    }
}

Update-WSL

# STEP 6: Set WSL default version to 2
function Set-WSLVersion2 {
    Write-Host "`nSetting WSL default version to 2..."
    $wslCheck = Get-Command wsl -ErrorAction SilentlyContinue
    if ($wslCheck) {
        try {
            wsl --set-default-version 2
            Write-Host "WSL default set to version 2 successfully."
        }
        catch {
            Write-Host "Failed to set default version to 2. This might require a reboot first."
            Write-Host "Error: $_"
        }
    }
    else {
        Write-Host "No 'wsl' command found, can't set default version. Possibly needs a reboot first."
    }
}

Set-WSLVersion2

# STEP 7: Set Execution Policy to RemoteSigned
function Configure-ExecutionPolicy {
    Write-Host "`nSetting PowerShell Execution Policy for current user..."
    try {
        Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
        Write-Host "Execution Policy set to RemoteSigned for CurrentUser."
    }
    catch {
        Write-Host "Could not set execution policy. Error: $_"
    }
}

Configure-ExecutionPolicy

# STEP 8: Prompt for Reboot if Needed
if ($Global:needsReboot) {
    Write-Host "`nOne or more WSL features or kernel updates were installed."
    Write-Host "A reboot is recommended to finalize changes."
    Write-Host "`nAfter the reboot, run the MAIN INSTALLER script (the one that imports Ubuntu & sets up NVIDIA SDK)."
    Write-Host "`nPress Enter to exit..."
    [void][System.Console]::ReadLine()
    exit
}
else {
    Write-Host "`nNo reboot required. It appears WSL and its kernel are already up to date."
    Write-Host "You're ready to run the MAIN INSTALLER script."
    Write-Host "`nPress Enter to exit..."
    [void][System.Console]::ReadLine()
}
