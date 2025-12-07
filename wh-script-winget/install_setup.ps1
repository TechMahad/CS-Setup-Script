# === WINGET-BASED INSTALLATION SCRIPT FOR WAREHOUSE ===
# This script uses winget to install applications instead of local installers

$desktopPath = [Environment]::GetFolderPath("Desktop")

# === FUNCTION: INSTALL APP USING WINGET ===
function Install-App-Winget {
    param (
        [string[]]$appIds,
        [string]$appName
    )

    Write-Host "Installing $appName using winget..."
    
    # Check if winget is available
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Error "winget is not available. Please install the App Installer from the Microsoft Store."
        return $false
    }

    # Try each provided app ID
    foreach ($appId in $appIds) {
        # Check if app is already installed
        $installed = winget list --id $appId --accept-source-agreements 2>$null
        if ($installed -match $appId) {
            Write-Host "$appName is already installed. Skipping..."
            return $true
        }

        # Try to install using winget
        Write-Host "Attempting to install using package ID: $appId"
        $result = winget install --id $appId --silent --accept-package-agreements --accept-source-agreements 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "$appName installed successfully."
            return $true
        } else {
            Write-Warning "Failed to install $appName with package ID: $appId"
        }
    }
    
    Write-Warning "Failed to install $appName with any of the provided package IDs. You may need to install it manually."
    return $false
}

# === COPY PRINTER DRIVERS (IF PROVIDED) ===
# Note: Printer drivers are hardware-specific and not available via winget.
# The script looks for printer drivers in a local Installers/PrinterDrivers folder
# relative to this script's location. Place your printer drivers there if needed.

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$printerDriversSource = Join-Path $scriptPath "Installers\PrinterDrivers"

if (Test-Path $printerDriversSource) {
    $destination = Join-Path $desktopPath "PrinterDrivers"
    Write-Host "Copying printer drivers from $printerDriversSource to desktop..."
    Copy-Item -Path $printerDriversSource -Destination $destination -Recurse -Force
    Write-Host "Copied printer drivers to desktop."
} else {
    Write-Host "Printer driver folder not found at: $printerDriversSource"
    Write-Host "If printer drivers are needed, place them in: Installers\PrinterDrivers (relative to this script)"
}

# === INSTALL APPLICATIONS USING WINGET ===
Install-App-Winget @("Google.Chrome", "Google.Chrome.MSIX") "Google Chrome"
Install-App-Winget @("Mozilla.Firefox", "Mozilla.Firefox.MSIX") "Mozilla Firefox"
Install-App-Winget @("QZ.QZTray", "qz-tray") "QZ Tray"

# WPS Office is commented out in the original script, so skipping it here
# Uncomment the line below if you want to install WPS Office:
# Install-App-Winget @("Kingsoft.WPSOffice", "WPSOffice") "WPS Office"

Write-Host "`nAll tasks complete."

