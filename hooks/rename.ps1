# Action type: rename (rename files by replacing target string in filename)

. "$PSScriptRoot/common.ps1"

function Invoke-RenameAction {
    param(
        [object]$Action,
        [hashtable]$Answers
    )
    
    Write-Host "  [Rename] Renaming files by replacing target string..." -ForegroundColor Cyan
    
    # Process target and value with placeholder replacement
    $target = Invoke-Replacement -Text $Action.target -Answers $Answers
    $value = Invoke-Replacement -Text $Action.value -Answers $Answers
    
    # Process files (support both array and object format)
    $filePatterns = @()
    $excludePatterns = @()
    
    if ($Action.files -is [array]) {
        # Legacy array format
        $filePatterns = $Action.files
    } elseif ($Action.files -is [PSCustomObject] -or $Action.files -is [hashtable]) {
        # New object format
        if ($Action.files.include) {
            foreach ($pattern in $Action.files.include) {
                $filePatterns += Invoke-Replacement -Text $pattern -Answers $Answers
            }
        }
        
        if ($Action.files.exclude) {
            foreach ($pattern in $Action.files.exclude) {
                $excludePatterns += Invoke-Replacement -Text $pattern -Answers $Answers
            }
        }
    }
    
    # Helper function to check if file should be processed
    $shouldProcessFile = {
        param([string]$FilePath)
        
        # Normalize path separators
        $normalizedPath = $FilePath -replace '\\', '/'
        
        # Check exclude patterns
        if ($excludePatterns.Count -gt 0) {
            foreach ($pattern in $excludePatterns) {
                $normalizedPattern = $pattern -replace '\\', '/'
                if ($normalizedPath -like "*$normalizedPattern*" -or $normalizedPath -like $normalizedPattern) {
                    return $false
                }
            }
        }
        
        return $true
    }
    
    # Collect all matching files
    $allFiles = @()
    $baseDir = Get-Location
    
    foreach ($pattern in $filePatterns) {
        $processedPattern = Invoke-Replacement -Text $pattern -Answers $Answers
        
        # Resolve path
        if ($processedPattern -match '^[a-zA-Z]:\\|^/') {
            # Absolute path
            $searchPath = $processedPattern
        } else {
            # Relative path
            $searchPath = Join-Path $baseDir $processedPattern
        }
        
        # Find files
        if ($processedPattern -match '\*') {
            # Glob pattern
            try {
                $matchedFiles = Get-ChildItem -Path $searchPath -File -ErrorAction Stop
                foreach ($file in $matchedFiles) {
                    if (& $shouldProcessFile $file.FullName) {
                        $allFiles += $file
                    }
                }
            } catch {
                Write-Host "    ℹ No files found for pattern: $processedPattern" -ForegroundColor Yellow
            }
        } else {
            # Direct file path
            if (Test-Path $searchPath -PathType Leaf) {
                $file = Get-Item $searchPath
                if (& $shouldProcessFile $file.FullName) {
                    $allFiles += $file
                }
            }
        }
    }
    
    if ($allFiles.Count -eq 0) {
        Write-Host "    ℹ No files found matching patterns" -ForegroundColor Yellow
        Write-Host "  ✓ Rename completed (no files to rename)" -ForegroundColor Green
        return
    }
    
    $renamedCount = 0
    $skippedCount = 0
    
    foreach ($file in $allFiles) {
        $originalName = $file.Name
        $originalPath = $file.FullName
        $parentDir = $file.DirectoryName
        
        # Check if filename contains the target string
        if ($originalName.Contains($target)) {
            # Replace target with value in filename
            $newName = $originalName -replace [regex]::Escape($target), $value
            $newPath = Join-Path $parentDir $newName
            
            # Skip if name hasn't changed
            if ($newName -eq $originalName) {
                Write-Host "    ℹ Skipped (no change): $originalName" -ForegroundColor Yellow
                $skippedCount++
                continue
            }
            
            # Check if target file already exists
            if (Test-Path $newPath) {
                Write-Host "    ✗ Target already exists: $newName" -ForegroundColor Red
                Write-Host "      Original: $originalName" -ForegroundColor Gray
                $skippedCount++
                continue
            }
            
            try {
                # Rename the file
                Rename-Item -Path $originalPath -NewName $newName -ErrorAction Stop
                Write-Host "    ✓ $originalName -> $newName" -ForegroundColor Green
                $renamedCount++
            } catch {
                Write-Host "    ✗ Failed to rename: $originalName" -ForegroundColor Red
                Write-Host "      Error: $_" -ForegroundColor Red
                $skippedCount++
            }
        } else {
            # Target string not found in filename
            Write-Host "    ℹ Skipped (target not found): $originalName" -ForegroundColor Yellow
            $skippedCount++
        }
    }
    
    # Summary
    Write-Host "  ✓ Rename completed: $renamedCount renamed, $skippedCount skipped" -ForegroundColor Green
}
