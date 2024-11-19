# DeclareData Fuse Windows Installer
# https://declaredata.com
# Version: 0.0.1 WIP Not Working

$ErrorActionPreference = 'Stop'

# Configuration
$AppVersion = "1.0.0"
$AppName = "fuse"
$InstallDir = Join-Path $env:LOCALAPPDATA "DeclareData\Fuse\bin"
$ConfigDir = Join-Path $env:APPDATA "DeclareData\Fuse"
$DefaultPort = 8080
$DownloadUrl = $env:INSTALLER_DOWNLOAD_URL ?? "https://releases.declaredata.com/fuse/1.0.0"

# Colors
$Colors = @{
    Red = "`e[31m"
    Green = "`e[32m"
    Blue = "`e[34m"
    Yellow = "`e[33m"
    Bold = "`e[1m"
    Reset = "`e[0m"
}

# Helpers
function Write-Error($Message) {
    Write-Host "$($Colors.Red)Error: $Message$($Colors.Reset)" -ForegroundColor Red
    exit 1
}

function Write-Status($Message) {
    Write-Host "$($Colors.Blue)=>$($Colors.Reset) $Message"
}

function Write-Success($Message) {
    Write-Host "$($Colors.Green)✓$($Colors.Reset) $Message"
}

function Write-Debug($Message) {
    if ($env:DEBUG -eq "1") {
        Write-Host "$($Colors.Yellow)DEBUG:$($Colors.Reset) $Message"
    }
}

# Spinner for async operations
function Show-Spinner {
    param(
        [scriptblock]$ScriptBlock,
        [string]$Message
    )
    
    $spinChars = "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"
    $job = Start-Job -ScriptBlock $ScriptBlock
    
    try {
        $i = 0
        while ($job.State -eq "Running") {
            Write-Host "`r$($Colors.Blue)$($spinChars[$i % $spinChars.Count])$($Colors.Reset) $Message" -NoNewline
            Start-Sleep -Milliseconds 100
            $i++
        }
        
        $result = Receive-Job $job
        if ($job.State -eq "Completed") {
            Write-Host "`r$($Colors.Green)✓$($Colors.Reset) $Message"
            return $result
        } else {
            Write-Host "`r$($Colors.Red)✗$($Colors.Reset) $Message"
            throw "Operation failed"
        }
    }
    finally {
        Remove-Job $job
    }
}

# Platform detection
function Get-Platform {
    $arch = switch($env:PROCESSOR_ARCHITECTURE) {
        "AMD64" { "x86_64" }
        "ARM64" { "arm64" }
        default { Write-Error "Unsupported architecture: $env:PROCESSOR_ARCHITECTURE" }
    }
    return "$arch-windows"
}

# Port selection
function Prompt-Port {
    Write-Host "Select Fuse Server Port $($Colors.Bold)[$DefaultPort]$($Colors.Reset): " -NoNewline
    $port = Read-Host
    
    if ([string]::IsNullOrWhiteSpace($port)) {
        $port = $DefaultPort
    }
    
    if ($port -match '^\d+$' -and [int]$port -gt 0 -and [int]$port -lt 65536) {
        Write-Success "Using port: $port"
    } else {
        $port = $DefaultPort
        Write-Success "Using default port: $port"
    }
    
    return $port
}

# Installation
function Install-Fuse {
    param($Platform, $Port)
    
    $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid())
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    
    try {
        # Download package
        $archive = "fuse-$Platform-latest.zip"
        $downloadUrl = "$DownloadUrl/$archive"
        $archivePath = Join-Path $tempDir $archive
        
        Write-Status "Downloading package..."
        Show-Spinner -Message "Downloaded Fuse package!" -ScriptBlock {
            Invoke-WebRequest -Uri $downloadUrl -OutFile $archivePath -UseBasicParsing
        }
        
        Write-Status "Installing..."
        Show-Spinner -Message "Installed Fuse!" -ScriptBlock {
            Expand-Archive -Path $archivePath -DestinationPath $tempDir -Force
            
            # Create directories
            New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
            
            # Install binary
            if (Test-Path "$tempDir\fuse-dist\bin") {
                Copy-Item "$tempDir\fuse-dist\bin\*" $InstallDir -Force
            } else {
                throw "Binary directory not found"
            }
            
            # Install libraries if they exist
            if (Test-Path "$tempDir\fuse-dist\lib") {
                $libDir = Join-Path (Split-Path $InstallDir) "lib"
                New-Item -ItemType Directory -Force -Path $libDir | Out-Null
                Copy-Item "$tempDir\fuse-dist\lib\*" $libDir -Recurse -Force
            }
        }
        
        Write-Status "Creating configuration..."
        Show-Spinner -Message "Created config toml here: $ConfigDir" -ScriptBlock {
            New-Item -ItemType Directory -Force -Path $ConfigDir | Out-Null
            
@"
[server]
port = $Port
host = "0.0.0.0"

[logging]
level = "info"
file = "fuse.log"
"@ | Set-Content (Join-Path $ConfigDir "fuse.toml") -Force
            
            New-Item -ItemType Directory -Force -Path (Join-Path $InstallDir "data") | Out-Null
        }
        
        if (-not (Test-Path (Join-Path $InstallDir "fuse.exe"))) {
            Write-Error "Installation verification failed"
        }
    }
    finally {
        Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue
    }
}

# Main installation flow
Write-Host "$($Colors.Bold)DeclareData Fuse Installer ($AppVersion)$($Colors.Reset)"
Write-Host "----------------------------------------"
Write-Host

# Check PowerShell version
if ($PSVersionTable.PSVersion.Major -lt 5) {
    Write-Error "PowerShell 5.0 or later is required"
}

# Get platform
Write-Status "Detecting platform..."
$platform = Get-Platform
$archiveUrl = "$DownloadUrl/fuse-$platform-latest.zip"
Write-Success "Platform detected: $platform"
Write-Success "Package URL: $archiveUrl"
Write-Success "Install directory: $InstallDir"
Write-Success "Config directory: $ConfigDir"
Write-Host

# Get port
Write-Status "Configuring Fuse server..."
if ([Environment]::UserInteractive) {
    $port = Prompt-Port
} else {
    Write-Success "Using default port in non-interactive mode: $DefaultPort"
    $port = $DefaultPort
}
Write-Host

# Install
Install-Fuse $platform $port

# Check PATH
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath -notlike "*$InstallDir*") {
    Write-Host
    Write-Status "PATH Configuration Required"
    Write-Host "Add Fuse to your PATH by running:"
    Write-Host "    [Environment]::SetEnvironmentVariable('Path', `$env:Path + ';$InstallDir', 'User')"
}

# Done
Write-Host
Write-Success "Installation Complete!"
Write-Host
Write-Host "$($Colors.Bold)Start Fuse:$($Colors.Reset)"
Write-Host "$($Colors.Blue)fuse start$($Colors.Reset)"
Write-Host
Write-Host "$($Colors.Bold)Check Fuse:$($Colors.Reset)"
Write-Host "$($Colors.Blue)fuse status$($Colors.Reset)"
Write-Host
Write-Host "$($Colors.Bold)Use Fuse with your existing PySpark code:$($Colors.Reset)"
Write-Host "$($Colors.Blue)from fuse_python.session import session$($Colors.Reset)"
Write-Host "$($Colors.Blue)import fuse_python.functions as F$($Colors.Reset)"
Write-Host
Write-Host "$($Colors.Bold)See also:$($Colors.Reset) https://declaredata.com/resources/playground"
