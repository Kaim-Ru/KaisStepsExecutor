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
    
    # Process destination placeholder
    $destination = Invoke-Replacement -Text $Action.destination -Answers $Answers
    
    # Resolve destination path
    if (-not [System.IO.Path]::IsPathRooted($destination)) {
        $destination = Join-Path (Get-Location) $destination
    }
    
    # Check if source is an array
    $sources = if ($Action.source -is [array]) {
        $Action.source
    } else {
        @($Action.source)
    }
    
    $copiedCount = 0
    $failedCount = 0
    
    foreach ($sourcePath in $sources) {
        # Process placeholders in source path
        $source = Invoke-Replacement -Text $sourcePath -Answers $Answers
        
        # Resolve source path
        if (-not [System.IO.Path]::IsPathRooted($source)) {
            $source = Join-Path (Get-Location) $source
        }
        
        if (-not (Test-Path $source)) {
            Write-Host "    ✗ Source not found: $source" -ForegroundColor Red
            $failedCount++
            continue
        }
        
        # Determine final destination path
        $finalDestination = $destination
        
        # If destination ends with / or \, treat it as a directory
        # and copy the source into it with its original name
        if ($Action.destination -match '[\\/]$') {
            if (Test-Path $source -PathType Container) {
                $folderName = Split-Path -Leaf $source
                $finalDestination = Join-Path $destination $folderName
            }
        }
        # Otherwise, if destination exists as a directory (and source is also a directory),
        # copy into that directory
        elseif ((Test-Path $source -PathType Container) -and (Test-Path $destination -PathType Container)) {
            $folderName = Split-Path -Leaf $source
            $finalDestination = Join-Path $destination $folderName
        }
        # If multiple sources and destination is a directory, copy each source into it
        elseif ($sources.Count -gt 1 -and (Test-Path $destination -PathType Container)) {
            $itemName = Split-Path -Leaf $source
            $finalDestination = Join-Path $destination $itemName
        }
        
        try {
            Copy-DirectoryRecursive -Source $source -Destination $finalDestination
            Write-Host "    ✓ $source -> $finalDestination" -ForegroundColor Green
            $copiedCount++
        } catch {
            Write-Host "    ✗ Copy failed: $source -> $finalDestination" -ForegroundColor Red
            Write-Host "      Error: $_" -ForegroundColor Red
            $failedCount++
        }
    }
    
    # Summary
    if ($failedCount -gt 0) {
        Write-Host "  ✓ Copy completed: $copiedCount succeeded, $failedCount failed" -ForegroundColor Yellow
        if ($copiedCount -eq 0) {
            throw "All copy operations failed"
        }
    } else {
        Write-Host "  ✓ Copy completed: $copiedCount file(s)/folder(s)" -ForegroundColor Green
    }
}
