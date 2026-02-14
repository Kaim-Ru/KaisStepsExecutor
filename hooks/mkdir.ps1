# Action type: mkdir (create directory)
# Example custom hook

. "$PSScriptRoot/common.ps1"

function Invoke-MkdirAction {
    param(
        [object]$Action,
        [hashtable]$Answers
    )
    
    Write-Host "  [Mkdir] Creating directory..." -ForegroundColor Cyan
    
    # Process placeholders in path
    $path = Invoke-Replacement -Text $Action.path -Answers $Answers
    
    # Resolve path
    if (-not [System.IO.Path]::IsPathRooted($path)) {
        $path = Join-Path (Get-Location) $path
    }
    
    # Create directory
    if (-not (Test-Path $path)) {
        try {
            New-Item -ItemType Directory -Path $path -Force | Out-Null
            Write-Host "    ✓ Created: $path" -ForegroundColor Green
            Write-Host "  ✓ Directory created successfully" -ForegroundColor Green
        } catch {
            Write-Host "    ✗ Failed to create directory: $_" -ForegroundColor Red
            throw
        }
    } else {
        Write-Host "    ℹ Already exists: $path" -ForegroundColor Yellow
        Write-Host "  ✓ Directory already exists (skipped)" -ForegroundColor Green
    }
}
