# Action type: symlink (create symbolic link)

. "$PSScriptRoot/../common.ps1"

function Invoke-SymlinkAction {
    param(
        [object]$Action,
        [hashtable]$Answers
    )
    
    Write-Host "  [Symlink] Creating symbolic link..." -ForegroundColor Cyan
    
    # Process placeholders in paths
    $source = Invoke-Replacement -Text $Action.source -Answers $Answers
    $destination = Invoke-Replacement -Text $Action.destination -Answers $Answers
    
    # Resolve paths
    if (-not [System.IO.Path]::IsPathRooted($source)) {
        $source = Join-Path (Get-Location) $source
    }
    if (-not [System.IO.Path]::IsPathRooted($destination)) {
        $destination = Join-Path (Get-Location) $destination
    }
    
    if (-not (Test-Path $source)) {
        Write-Host "    ✗ Source not found: $source" -ForegroundColor Red
        throw "Symlink source not found: $source"
    }
    
    # If destination ends with / or \, treat it as a directory
    # and create symlink inside it with the source's original name
    if ($Action.destination -match '[\\/]$') {
        $linkName = Split-Path -Leaf $source
        $destination = Join-Path $destination $linkName
    }
    # Otherwise, if destination exists as a directory, create symlink inside it
    elseif (Test-Path $destination -PathType Container) {
        $linkName = Split-Path -Leaf $source
        $destination = Join-Path $destination $linkName
    }
    
    try {
        New-Item -ItemType SymbolicLink -Path $destination -Target $source -Force -ErrorAction Stop | Out-Null
        Write-Host "    ✓ $source -> $destination" -ForegroundColor Green
        Write-Host "  ✓ Symbolic link created" -ForegroundColor Green
    } catch {
        Write-Host "    ✗ Failed to create symbolic link: $_" -ForegroundColor Red
        Write-Host "    ℹ Administrator privileges may be required." -ForegroundColor Yellow
        throw
    }
}
