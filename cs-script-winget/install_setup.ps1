# === WINGET-BASED INSTALLATION SCRIPT ===
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

# === INSTALL CHROME FIRST ===
Install-App-Winget @("Google.Chrome", "Google.Chrome.MSIX") "Google Chrome"

# === FORCE-LAUNCH CHROME TO GENERATE PROFILE ===
$chromeExe = "$env:ProgramFiles\Google\Chrome\Application\chrome.exe"
if (-not (Test-Path $chromeExe)) {
    $chromeExe = "$env:ProgramFiles(x86)\Google\Chrome\Application\chrome.exe"
}

if (Test-Path $chromeExe) {
    Write-Host "Launching Chrome to initialize profile..."
    Start-Process $chromeExe "about:blank"
    Start-Sleep -Seconds 5
    Get-Process chrome -ErrorAction SilentlyContinue | Stop-Process -Force
    Start-Sleep -Seconds 2
} else {
    Write-Warning "Chrome executable not found; skipping profile init."
}

# === ADD CHROME BOOKMARKS ===
$chromeProfile = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default"
$bookmarksFile = "$chromeProfile\Bookmarks"

if (-not (Test-Path $chromeProfile)) {
    Write-Warning "Chrome profile folder not found; skipping bookmark injection."
} else {
    $customBookmarks = @{
        roots = @{
            bookmark_bar = @{
                children = @(
                    @{ name = "ADP"; url = "https://online.adp.com/signin/v1/?APPID=WFNPortal&productId=80e309c3-7085-bae1-e053-3505430b5495&returnURL=https://workforcenow.adp.com/&callingAppId=WFN&TARGET=-SM-https://workforcenow.adp.com/theme/index.html"; type = "url" },
                    @{ name = "Quick Timestamp"; url = "https://tlmisi2.adp.com/adptlmqts/quickTS.aspx"; type = "url" },
                    @{ name = "Console"; url = "https://cs.dressbad.com/dbadmin/spring-controller/admin/login?r=aHR0cHM6Ly9jcy5kcmVzc2JhZC5jb206NDQzL2RiYWRtaW4vY3MvY29uc29sZS9PcmRlckxvb2t1cC5qc3A="; type = "url" },
                    @{ name = "Clone Console"; url = "https://clone.dressbad.com/dbadmin/spring-controller/admin/login?r=aHR0cHM6Ly9jbG9uZS5kcmVzc2JhZC5jb206NDQzL2RiYWRtaW4vY3MvY29uc29sZS9PcmRlckxvb2t1cC5qc3A="; type = "url" },
                    @{ name = "Kustomer"; url = "https://revolve.kustomerapp.com/app/customers"; type = "url" },
                    @{ name = "Authorize.Net"; url = "https://account.authorize.net/"; type = "url" },
                    @{ name = "Check Coupon"; url = "http://box.myblueadmin.com/dbadmin/spring-controller/admin/login?r=aHR0cDovL2JveC5teWJsdWVhZG1pbi5jb206ODAvZGJhZG1pbi90b29scy9DaGVja0NvdXBvbi5qc3A="; type = "url" },
                    @{ name = "Check Coupon (Email)"; url = "http://box.myblueadmin.com/dbadmin/spring-controller/admin/login?r=aHR0cDovL2JveC5teWJsdWVhZG1pbi5jb206ODAvZGJhZG1pbi90b29scy9DaGVja0NvdXBvbkN1c3RvbWVyLmpzcA=="; type = "url" },
                    @{ name = "Store Credit History"; url = "http://box.myblueadmin.com/dbadmin/spring-controller/admin/login?r=aHR0cDovL2JveC5teWJsdWVhZG1pbi5jb206ODAvZGJhZG1pbi9TaG93U3RvcmVDcmVkaXRIaXN0b3J5LmpzcA=="; type = "url" },
                    @{ name = "NTF"; url = "http://box.myblueadmin.com/dbadmin/spring-controller/admin/login?r=aHR0cDovL2JveC5teWJsdWVhZG1pbi5jb206ODAvZGJhZG1pbi9zcHJpbmctY29udHJvbGxlci9tYXJrZXRpbmcvc2VhcmNoTmV3VG9GaWxlQ291cG9u"; type = "url" }
                )
                name = "Bookmarks bar"
                type = "folder"
            }
            other = @{ children = @(); name = "Other bookmarks"; type = "folder" }
            synced = @{ children = @(); name = "Mobile bookmarks"; type = "folder" }
        }
        version = 1
    }

    $customBookmarks | ConvertTo-Json -Depth 10 | Set-Content -Path $bookmarksFile -Encoding UTF8
    Write-Host "Chrome bookmarks have been configured."
}

# === INSTALL WPS OFFICE AND SLACK ===
Install-App-Winget @("Kingsoft.WPSOffice", "WPSOffice") "WPS Office"
Install-App-Winget @("SlackTechnologies.Slack", "Slack.Slack") "Slack"

# === CREATE SHORTCUT TO SHARED FOLDER ===
$shortcutPath = Join-Path $desktopPath "CS Share.lnk"
$targetPath = "\\192.168.0.100\cs"
$wshShell = New-Object -ComObject WScript.Shell
$shortcut = $wshShell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = $targetPath
$shortcut.Save()
Write-Host "Created desktop shortcut to shared folder."

# === INSTALL PRITUNL LAST ===
# Note: Pritunl may not be available in winget. If not, you may need to install manually or use a different method.
Install-App-Winget @("Pritunl.Pritunl", "PritunlClient.PritunlClient") "Pritunl"

Write-Host "`nAll tasks complete."

