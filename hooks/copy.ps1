# Action type: copy (copy file or folder)

. "$PSScriptRoot/common.ps1"

function Copy-DirectoryRecursive {
    param(
        [string]$Source,
        [string]$Destination
    )
    
    if (Test-Path $Source -PathType Container) {
        # Source is a directory
        if (-not (Test-Path $Destination)) {
            New-Item -ItemType Directory -Path $Destination -Force | Out-Null
        }
        Copy-Item -Path "$Source/*" -Destination $Destination -Recurse -Force
    } else {
        # Source is a file
        $destDir = Split-Path -Parent $Destination
        if ($destDir -and -not (Test-Path $destDir)) {
            New-Item -ItemType Directory -Path $destDir -Force | Out-Null
        }
        
        # If destination is a directory, copy file into it
        if (Test-Path $Destination -PathType Container) {
            Copy-Item -Path $Source -Destination $Destination -Force
        } else {
            # Destination is a file path
            Copy-Item -Path $Source -Destination $Destination -Force
        }
    }
}

function Invoke-CopyAction {
    param(
        [object]$Action,
        [hashtable]$Answers
    )
    
    Write-Host "  [Copy] Copying file/folder..." -ForegroundColor Cyan
    
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
        throw "Copy source not found: $source"
    }
    
    # If destination ends with / or \, treat it as a directory
    # and copy the source into it with its original name
    if ($Action.destination -match '[\\/]$') {
        if (Test-Path $source -PathType Container) {
            $folderName = Split-Path -Leaf $source
            $destination = Join-Path $destination $folderName
        }
    }
    # Otherwise, if destination exists as a directory (and source is also a directory),
    # copy into that directory
    elseif ((Test-Path $source -PathType Container) -and (Test-Path $destination -PathType Container)) {
        $folderName = Split-Path -Leaf $source
        $destination = Join-Path $destination $folderName
    }
    
    try {
        Copy-DirectoryRecursive -Source $source -Destination $destination
        Write-Host "    ✓ $source -> $destination" -ForegroundColor Green
        Write-Host "  ✓ Copy completed" -ForegroundColor Green
    } catch {
        Write-Host "    ✗ Copy failed: $_" -ForegroundColor Red
        throw
    }
}
