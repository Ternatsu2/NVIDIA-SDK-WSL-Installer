
# NVIDIA SDK WSL Installer

Automates the installation and configuration of:
- **Windows Subsystem for Linux (WSL)**
- **Ubuntu 22.04 (Makes a custom distribution so you don't have to worry about overwriting your files)**
- **NVIDIA SDK Manager**
  
PLEASE NOTE THAT YOU MUST DOWNLOAD THE PREREQUISITES BEFORE RUNNING THE EXE.
This **executable** streamlines the entire setup process for developers and engineers using NVIDIA tools and WSL on Windows. 

---

## What It Does

1. Checks if WSL is installed and, if not, enables and installs it.
2. Installs Ubuntu 22.04.
3. Installs required dependencies (including Google Chrome in WSL).
4. Installs the NVIDIA SDK Manager from your provided `.deb` file.

---

To ensure the user has everything they need to successfully run your script, here’s a checklist of requirements:

---

#### **Prerequisites**
Before running the script, ensure you have the following:
1. **Ubuntu 22.04 Tarball `.tar`**
   - Download it from this link: https://drive.google.com/file/d/1pZXml5XwobZBa3Mft7ejphfUNqWAy81K/view?usp=drive_link
   - Place it in your `Downloads` folder.
2. **NVIDIA SDK Manager `.deb` File**
   - Download it from: https://developer.nvidia.com/nvidia-sdk-manager
   - Place it in your `Downloads` folder.
3. **Disk Space**
   - Ensure at least 10 GB of free disk space is available.

---

## Usage (After you meet the prerequisites)

1. **Download** the `PrerequisiteInstaller.exe`.
2. **Download** the `InstallNVIDIASDK_Automated.exe`.
3. **Right-click** on `PrerequisiteInstaller.exe` → **Run as Administrator**. (Note that after running this script, you will be prompted to hit "Enter" to restart your computer and finish other changes.)
4. When the restart is done, **Right-click** on `InstallNVIDIASDK_Automated.exe` → **Run as Administrator**.
5. When the script is finished, it will open SDK Manager on its own.

That’s it. The script automatically performs all tasks behind the scenes. Once it finishes, you can open WSL and verify that Ubuntu is set up and the NVIDIA SDK Manager is installed.
For detailed guidance on using NVIDIA SDK Manager, visit NVIDIA's official SDK Manager documentation. https://developer.nvidia.com/sdk-manager

---

## Troubleshooting

- **“File Not Found”**:  
  Make sure the `.deb` and `.tar` files are in your Downloads folder.  
- **Missing WSL**:  
  The installer will enable it if needed, but ensure your Windows version supports it.  
- **Administrator Privileges**:  
  If the installer won’t run, verify you’re running it as admin. Right-click → **Run as Administrator**.  


---

## Contributing

Have ideas or need additional features? Feel free to open an issue or submit a pull request. We welcome any improvements or bug reports.

---

## License

Licensed under the [MIT License](LICENSE). Check the LICENSE file for details.

---

**Enjoy the easy WSL + NVIDIA SDK Manager setup on Windows!**
