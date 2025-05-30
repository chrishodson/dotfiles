<#
.SYNOPSIS
    Starts or restarts the Plex Media Server in a Docker container.
.DESCRIPTION
    This script pulls the latest Plex Docker image, stops and removes any existing
    Plex container, and starts a new one with the specified configuration.
.PARAMETER ConfigPath
    Path to the Plex configuration directory. Default is C:\plex\database
.PARAMETER TranscodePath
    Path to the Plex transcode directory. Default is C:\plex\transcode
.PARAMETER MediaPath
    Path to the Plex media directory. Default is C:\plex\media
.PARAMETER TimeZone
    TimeZone to use in the container. Default is America/New_York
.EXAMPLE
    .\StartPlexServer.ps1 -MediaPath D:\Media
#>
param (
    [string]$ConfigPath = "C:\plex\database",
    [string]$TranscodePath = "C:\plex\transcode",
    [string]$MediaPath = "C:\plex\media",
    [string]$TimeZone = "America/New_York"
)

function Write-Log {
    param ([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    switch ($Level) {
        "ERROR" { Write-Error "[$timestamp] ERROR: $Message" }
        "WARN"  { Write-Warning "[$timestamp] WARNING: $Message" }
        "INFO"  { Write-Host "[$timestamp] INFO: $Message" }
    }
}

# Verify Docker is installed and running
try {
    $null = docker info 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Log "Docker is not running or not installed" "ERROR"
        exit 1
    }
} catch {
    Write-Log "Docker is not available: $_" "ERROR"
    exit 1
}

# Verify directories exist
foreach ($path in @($ConfigPath, $TranscodePath, $MediaPath)) {
    if (-not (Test-Path -Path $path)) {
        Write-Log "Creating directory: $path" "WARN"
        try {
            New-Item -Path $path -ItemType Directory -Force | Out-Null
        } catch {
            Write-Log "Failed to create directory ${path}: ${_}" "ERROR"
            exit 1
        }
    }
}

# Pull the latest Plex Docker image
Write-Log "Pulling latest Plex Docker image..."
try {
    docker pull plexinc/pms-docker:latest
    if ($LASTEXITCODE -ne 0) { throw "Docker pull failed" }
} catch {
    Write-Log "Failed to pull the latest Plex Docker image: ${_}" "ERROR"
    exit 1
}

# Stop existing Plex container if running
$plexRunning = docker ps | Select-String -Pattern "plex"
if ($plexRunning) {
    Write-Log "Stopping existing Plex container..."
    try {
        docker stop plex
        if ($LASTEXITCODE -ne 0) { throw "Docker stop failed" }
    } catch {
        Write-Log "Failed to stop Plex container: ${_}" "ERROR"
        exit 1
    }
}

# Remove existing Plex container
Write-Log "Removing any existing Plex container..."
try {
    $removeOutput = docker rm plex 2>&1
    if ($LASTEXITCODE -ne 0 -and $removeOutput -notlike "*No such container*") {
        throw "Docker remove failed: $removeOutput"
    }
} catch {
    # Only log if it's not the "No such container" error
    if ($_ -notlike "*No such container*") {
        Write-Log "Note: No existing Plex container to remove" "INFO"
    }
}

# Start new Plex container
Write-Log "Starting Plex container..."
try {
    # Use explicit port mappings for better Windows compatibility
    docker run -d `
        --name plex `
        -p 32400:32400/tcp `
        -p 3005:3005/tcp `
        -p 8324:8324/tcp `
        -p 32469:32469/tcp `
        -p 1900:1900/udp `
        -p 32410:32410/udp `
        -p 32412:32412/udp `
        -p 32413:32413/udp `
        -p 32414:32414/udp `
        --restart=unless-stopped `
        -e TZ=$TimeZone `
        -v ${ConfigPath}:/config `
        -v ${TranscodePath}:/transcode `
        -v ${MediaPath}:/data `
        plexinc/pms-docker:latest
    
    if ($LASTEXITCODE -ne 0) { throw "Docker run failed" }
    Write-Log "Plex container started successfully"
} catch {
    Write-Log "Failed to start Plex container: ${_}" "ERROR"
    exit 1
}

Write-Log "Plex server is now running. Access it at http://localhost:32400/web"