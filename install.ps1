# ==============================================================================
# Necropsy Forensics Platform — Windows Automated 1-Click Installer
# ==============================================================================

[CmdletBinding()]
param (
    [switch]$Doctor
)

$ErrorActionPreference = "Stop"

$AppDisplayName = "Necropsy"
$InstallDir = $PSScriptRoot
if (-not $InstallDir) {
    $InstallDir = (Get-Item -Path ".").FullName
}

function Show-Banner {
    Write-Host @"
  _   _                                           
 | \ | | ___  ___ _ __ ___  _ __  ___ _   _       
 |  \| |/ _ \/ __| '__/ _ \| '_ \/ __| | | |      
 | |\  |  __/ (__| | | (_) | |_) \__ \ |_| |      
 |_| \_|\___|\___|_|  \___/| .__/|___/\__, |      
                           |_|        |___/       
  Next-Generation Digital Forensics Analysis Platform
"@ -ForegroundColor Cyan
    Write-Host "Windows Automated 1-Click Installer" -ForegroundColor White
    Write-Host "Target Directory: $InstallDir`n" -ForegroundColor Gray
}

function Test-JavaFX([string]$JavaExe) {
    try {
        $process = Start-Process -FilePath $JavaExe -ArgumentList "--add-modules javafx.controls -version" -NoNewWindow -PassThru -Wait -ErrorAction SilentlyContinue
        return ($process.ExitCode -eq 0)
    } catch {
        return $false
    }
}

function Run-Diagnostics {
    Write-Host "`n=== Necropsy Windows Environment Diagnostics ===" -ForegroundColor Cyan
    $allGood = $true

    # 1. OS & Architecture
    $is64Bit = [Environment]::Is64BitOperatingSystem
    Write-Host "  [✓] OS Architecture: $(if ($is64Bit) {'64-bit (x64)'} else {'32-bit'})" -ForegroundColor Green

    # 2. Check JRE
    $jreDir = Join-Path $InstallDir "jre"
    $confFile = Join-Path $InstallDir "etc\necropsy.conf"
    $javaPath = ""

    if (Test-Path "$jreDir\bin\java.exe") {
        $javaPath = "$jreDir\bin\java.exe"
    } elseif ($env:JAVA_HOME -and (Test-Path "$env:JAVA_HOME\bin\java.exe")) {
        $javaPath = "$env:JAVA_HOME\bin\java.exe"
    }

    if ($javaPath) {
        $hasFX = Test-JavaFX -JavaExe $javaPath
        if ($hasFX) {
            Write-Host "  [✓] Java Runtime: $javaPath (JavaFX Support Verified)" -ForegroundColor Green
        } else {
            Write-Host "  [!] Java Runtime: $javaPath (Missing JavaFX - Liberica Full recommended)" -ForegroundColor Yellow
            $allGood = $false
        }
    } else {
        Write-Host "  [✗] Java Runtime: Not found in jre\ or JAVA_HOME" -ForegroundColor Red
        $allGood = $false
    }

    # 3. Check Icons
    $iconPath = Join-Path $InstallDir "icons\icon.ico"
    if (Test-Path $iconPath) {
        Write-Host "  [✓] Necropsy Branding & Icons: Verified ($iconPath)" -ForegroundColor Green
    } else {
        Write-Host "  [!] Necropsy Branding Icons: Missing" -ForegroundColor Yellow
    }

    # 4. Check Desktop Shortcut
    $desktopPath = [Environment]::GetFolderPath("Desktop")
    $shortcutPath = Join-Path $desktopPath "Necropsy.lnk"
    if (Test-Path $shortcutPath) {
        Write-Host "  [✓] Desktop Shortcut: Installed ($shortcutPath)" -ForegroundColor Green
    } else {
        Write-Host "  [i] Desktop Shortcut: Not created yet" -ForegroundColor Cyan
    }

    Write-Host "-----------------------------------------------------"
    if ($allGood) {
        Write-Host "Diagnostic Result: All systems ready for Necropsy on Windows!`n" -ForegroundColor Green
    } else {
        Write-Host "Diagnostic Result: Run 'install.bat' to auto-bundle portable JavaFX runtime.`n" -ForegroundColor Yellow
    }
}

function Provision-PortableJRE {
    $jreDir = Join-Path $InstallDir "jre"
    if (Test-Path "$jreDir\bin\java.exe") {
        Write-Host "Portable Java runtime already exists in $jreDir." -ForegroundColor Green
        return
    }

    Write-Host "`nProvisioning self-contained JavaFX Runtime (Zero Java Dependency Mode)..." -ForegroundColor Cyan
    $downloadUrl = "https://download.bell-sw.com/java/17.0.12+10/bellsoft-jre17.0.12+10-windows-amd64-full.zip"
    $tempZip = Join-Path $env:TEMP "necropsy_jre_temp.zip"

    Write-Host "Downloading BellSoft Liberica Full JRE (with JavaFX) from $downloadUrl..." -ForegroundColor Yellow
    Invoke-WebRequest -Uri $downloadUrl -OutFile $tempZip -UseBasicParsing

    Write-Host "Extracting portable JRE into $InstallDir\jre..." -ForegroundColor Cyan
    $extractTemp = Join-Path $env:TEMP "necropsy_jre_extract"
    if (Test-Path $extractTemp) { Remove-Item -Path $extractTemp -Recurse -Force }
    Expand-Archive -Path $tempZip -DestinationPath $extractTemp -Force

    $subFolder = Get-ChildItem -Path $extractTemp | Where-Object { $_.PSIsContainer } | Select-Object -First 1
    if ($subFolder) {
        Move-Item -Path $subFolder.FullName -Destination $jreDir -Force
    }
    Remove-Item -Path $tempZip -Force -ErrorAction SilentlyContinue
    Remove-Item -Path $extractTemp -Recurse -Force -ErrorAction SilentlyContinue

    Write-Host "Portable JRE provisioned successfully in $jreDir!" -ForegroundColor Green
}

function Update-Configuration {
    $confDir = Join-Path $InstallDir "etc"
    if (-not (Test-Path $confDir)) { New-Item -ItemType Directory -Path $confDir -Force | Out-Null }
    $confPath = Join-Path $confDir "necropsy.conf"

    $templatePath = Join-Path $InstallDir "installer_autopsy\etc\necropsy.conf"
    if (-not (Test-Path $confPath) -and (Test-Path $templatePath)) {
        Copy-Item -Path $templatePath -Destination $confPath -Force
    }

    if (Test-Path $confPath) {
        $content = Get-Content -Path $confPath -Raw
        if ($content -match '^\s*jdkhome=') {
            $content = $content -replace '^\s*jdkhome=.*', 'jdkhome="jre"'
        } else {
            $content += "`njdkhome=`"jre`"`n"
        }
        Set-Content -Path $confPath -Value $content -Force
    }
    Write-Host "Updated configuration: $confPath (jdkhome=`"jre`")" -ForegroundColor Green
}

function Create-WindowsShortcuts {
    $wsh = New-Object -ComObject WScript.Shell
    $iconPath = Join-Path $InstallDir "icons\icon.ico"
    $targetExe = Join-Path $InstallDir "bin\necropsy64.exe"
    if (-not (Test-Path $targetExe)) {
        $targetExe = Join-Path $InstallDir "bin\necropsy.exe"
    }

    # Desktop Shortcut
    $desktopPath = [Environment]::GetFolderPath("Desktop")
    $shortcutPath = Join-Path $desktopPath "Necropsy.lnk"
    $shortcut = $wsh.CreateShortcut($shortcutPath)
    $shortcut.TargetPath = $targetExe
    $shortcut.WorkingDirectory = $InstallDir
    $shortcut.IconLocation = "$iconPath, 0"
    $shortcut.Description = "Necropsy Next-Generation Digital Forensics Platform"
    $shortcut.Save()
    Write-Host "Created Desktop Shortcut: $shortcutPath" -ForegroundColor Green

    # Start Menu Shortcut
    $programsPath = [Environment]::GetFolderPath("Programs")
    $startMenuDir = Join-Path $programsPath "Necropsy"
    if (-not (Test-Path $startMenuDir)) { New-Item -ItemType Directory -Path $startMenuDir -Force | Out-Null }
    $startMenuShortcut = $wsh.CreateShortcut((Join-Path $startMenuDir "Necropsy.lnk"))
    $startMenuShortcut.TargetPath = $targetExe
    $startMenuShortcut.WorkingDirectory = $InstallDir
    $startMenuShortcut.IconLocation = "$iconPath, 0"
    $startMenuShortcut.Description = "Necropsy Digital Forensics Platform"
    $startMenuShortcut.Save()
    Write-Host "Created Start Menu Shortcut in $startMenuDir" -ForegroundColor Green
}

# Execution Entry Point
Show-Banner

if ($Doctor) {
    Run-Diagnostics
    exit 0
}

Provision-PortableJRE
Update-Configuration
Create-WindowsShortcuts
Run-Diagnostics

Write-Host @"
=====================================================
✓ Necropsy is successfully installed and configured!
=====================================================
You can launch Necropsy anytime by double-clicking the
'Necropsy' shortcut on your Desktop or in the Start Menu.
"@ -ForegroundColor Green
