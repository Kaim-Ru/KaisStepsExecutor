# Action type: rename (rename files with placeholder replacement)

. "$PSScriptRoot/common.ps1"

function Invoke-RenameAction {
    param(
        [object]$Action,
        [hashtable]$Answers
    )
    
    Write-Host "  [Rename] Renaming files with placeholder replacement..." -ForegroundColor Cyan
    
    # Process placeholders in files pattern
    $filesPattern = Invoke-Replacement -Text $Action.files -Answers $Answers
    
    # Resolve path
    $baseDir = Get-Location
    if ($filesPattern -match '^[a-zA-Z]:\\|^/') {
        # Absolute path
        $searchPath = $filesPattern
    } else {
        # Relative path
        $searchPath = Join-Path $baseDir $filesPattern
    }
    
    # Find files matching the pattern
    $files = @()
    
    # Support glob patterns
    if ($filesPattern -match '\*') {
        # Get all matching files
        try {
            $files = Get-ChildItem -Path $searchPath -File -ErrorAction Stop
        } catch {
            Write-Host "    ✗ No files found matching pattern: $filesPattern" -ForegroundColor Red
            throw "No files found matching pattern: $filesPattern"
        }
    } else {
        # Direct file path
        if (Test-Path $searchPath -PathType Leaf) {
            $files = @(Get-Item $searchPath)
        } else {
            Write-Host "    ✗ File not found: $filesPattern" -ForegroundColor Red
            throw "File not found: $filesPattern"
        }
    }
    
    if ($files.Count -eq 0) {
        Write-Host "    ℹ No files found matching pattern: $filesPattern" -ForegroundColor Yellow
        Write-Host "  ✓ Rename completed (no files to rename)" -ForegroundColor Green
        return
    }
    
    $renamedCount = 0
    $skippedCount = 0
    
    foreach ($file in $files) {
        $originalName = $file.Name
        $originalPath = $file.FullName
        $parentDir = $file.DirectoryName
        
        # Check if filename contains placeholders
        if ($originalName -match '\[\[\[.*?\]\]\]') {
            # Replace placeholders in filename
            $newName = Invoke-Replacement -Text $originalName -Answers $Answers
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
            }
        } else {
            # No placeholders found in filename
            Write-Host "    ℹ Skipped (no placeholders): $originalName" -ForegroundColor Yellow
            $skippedCount++
        }
    }
    
    # Summary
    Write-Host "  ✓ Rename completed: $renamedCount renamed, $skippedCount skipped" -ForegroundColor Green
}
