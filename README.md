# NVIDIA SDK WSL Installer

Automates the installation and configuration of:
- **Windows Subsystem for Linux (WSL)**
- **Ubuntu (22.04 or 24.04)**
- **NVIDIA SDK Manager**

This PowerShell script simplifies the setup process for developers and engineers working with NVIDIA tools and WSL environments on Windows.

---

## Features

- Automatically checks for WSL and installs it if necessary.
- Offers the choice of Ubuntu versions (22.04 or 24.04).
- Installs required dependencies for NVIDIA SDK Manager.
- Guides the user through placing the SDK Manager `.deb` file in the correct location.
- Runs the installation silently with minimal user input.

---

## Prerequisites

1. **Windows System**:
   - Ensure your Windows version supports WSL (Windows 10 version 2004 or later, or Windows 11).
   
2. **PowerShell**:
   - Run PowerShell as an Administrator.

3. **NVIDIA SDK Manager**:
   - Download the `.deb` installer from [NVIDIA Developer](https://developer.nvidia.com/nvidia-sdk-manager).
   - Place the `.deb` file in your Downloads folder.

---

## Installation

### Steps to Follow

1. **Clone the Repository**  
   Open a terminal and clone the repository to your local system:
   ```bash
   git clone https://github.com/your-username/NVIDIA-SDK-WSL-Installer.git
   cd NVIDIA-SDK-WSL-Installer
   ```

2. **Open PowerShell as Administrator**  
   Launch PowerShell with Administrator privileges:
   - Press `Win + S` to open the search bar.
   - Type `PowerShell`.
   - Right-click on "Windows PowerShell" and select **Run as Administrator**.

3. **Navigate to the Repository Directory**  
   Use the `cd` command to navigate to the directory where the repository was cloned:
   ```powershell
   cd C:\path\to\NVIDIA-SDK-WSL-Installer
   ```

4. **Run the Script**  
   Execute the PowerShell script:
   ```powershell
   .\InstallWSL.ps1
   ```

5. **Follow On-Screen Prompts**  
   - Choose the Ubuntu version (22.04 or 24.04) when prompted.
   - Ensure the NVIDIA SDK Manager `.deb` file is placed in your Downloads folder.

6. **Monitor Progress**  
   - The script will perform all the necessary setup steps automatically.
   - Progress and any issues will be logged to `install_log.txt` in your Downloads folder.

7. **Verify Installation**  
   Once the script completes:
   - Open WSL and verify the Ubuntu version.
   - Launch NVIDIA SDK Manager to confirm it was installed successfully.

8. **Troubleshoot if Needed**  
   If any issues arise, refer to the `install_log.txt` file or the Troubleshooting section in the README. 

