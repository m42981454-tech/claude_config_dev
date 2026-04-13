$ErrorActionPreference = "Stop"

Write-Host "==> Claude config bootstrap starting..."

$ClaudeDir = Join-Path $HOME ".claude"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

New-Item -ItemType Directory -Force -Path $ClaudeDir | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $ClaudeDir "plugins") | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $ClaudeDir "plugins\claude-hud") | Out-Null

function Copy-IfExists {
    param(
        [string]$Source,
        [string]$Destination
    )

    if (Test-Path $Source) {
        Copy-Item -Force $Source $Destination
        Write-Host "Copied: $Source"
    }
    else {
        Write-Host "Skip missing: $Source"
    }
}

Write-Host "==> Copying tracked config files..."
Copy-IfExists (Join-Path $ScriptDir "settings.json") (Join-Path $ClaudeDir "settings.json")
Copy-IfExists (Join-Path $ScriptDir "plugins\installed_plugins.json") (Join-Path $ClaudeDir "plugins\installed_plugins.json")
Copy-IfExists (Join-Path $ScriptDir "plugins\known_marketplaces.json") (Join-Path $ClaudeDir "plugins\known_marketplaces.json")
Copy-IfExists (Join-Path $ScriptDir "plugins\claude-hud\config.json") (Join-Path $ClaudeDir "plugins\claude-hud\config.json")

Write-Host "==> Ensuring runtime directories exist..."
@(
    "backups",
    "cache",
    "debug",
    "downloads",
    "file-history",
    "projects",
    "session-env",
    "sessions",
    "shell-snapshots",
    "statsig",
    "todos"
) | ForEach-Object {
    New-Item -ItemType Directory -Force -Path (Join-Path $ClaudeDir $_) | Out-Null
}

Write-Host "==> Bootstrap complete."
Write-Host ""
Write-Host "Next step:"
Write-Host "1. Start Claude Code once"
Write-Host "2. Check whether plugins are recognized"
Write-Host "3. If some plugins are missing, install them manually once in Claude Code"