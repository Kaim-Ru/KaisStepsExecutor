# Action type: replace (string replacement in files)

. "$PSScriptRoot/common.ps1"

function Invoke-ReplaceAction {
    param(
        [object]$Action,
        [hashtable]$Answers
    )
    
    Write-Host "  [Replace] Replacing strings in files..." -ForegroundColor Cyan
    
    # Process value with placeholder replacement
    $value = Invoke-Replacement -Text $Action.value -Answers $Answers
    
    # Process target (support string, regex object, or array)
    $targets = @()
    $isRegex = $false
    
    if ($Action.target -is [PSCustomObject] -and $Action.target.regex) {
        # Regex format
        $processedRegex = Invoke-Replacement -Text $Action.target.regex -Answers $Answers
        $targets += $processedRegex
        $isRegex = $true
    } elseif ($Action.target -is [array]) {
        # Array format - process placeholders in each element
        foreach ($t in $Action.target) {
            $targets += Invoke-Replacement -Text $t -Answers $Answers
        }
    } else {
        # String format (legacy)
        $targets += Invoke-Replacement -Text $Action.target -Answers $Answers
    }
    
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
    
    # Helper function to perform replacement in content
    $replaceInContent = {
        param([string]$Content)
        
        $newContent = $Content
        $hasMatch = $false
        
        if ($isRegex) {
            # Regex replacement
            foreach ($target in $targets) {
                if ($newContent -match $target) {
                    $hasMatch = $true
                    $newContent = $newContent -replace $target, $value
                }
            }
        } else {
            # String replacement (for each target in array or single target)
            foreach ($target in $targets) {
                if ($newContent.Contains($target)) {
                    $hasMatch = $true
                    $newContent = $newContent.Replace($target, $value)
                }
            }
        }
        
        if ($hasMatch) {
            # Process any remaining placeholders (like UUIDv4) in the content
            $newContent = Invoke-Replacement -Text $newContent -Answers $Answers
            return @{ Success = $true; Content = $newContent }
        }
        
        return @{ Success = $false; Content = $null }
    }
    
    $filesProcessed = 0
    
    foreach ($filePattern in $filePatterns) {
        # Process placeholders in file pattern
        $filePattern = Invoke-Replacement -Text $filePattern -Answers $Answers
        
        # Resolve path (support both absolute and relative paths)
        $resolvedPath = $filePattern
        if (-not [System.IO.Path]::IsPathRooted($filePattern)) {
            $resolvedPath = Join-Path (Get-Location) $filePattern
        }
        
        # Extract directory and pattern for Get-ChildItem
        $parentPath = Split-Path -Parent $resolvedPath
        $pattern = Split-Path -Leaf $resolvedPath
        
        # Handle wildcards
        if ($pattern -match '[\*\?]' -or $parentPath -match '[\*\?]') {
            # Use Get-ChildItem with recursion if ** is present
            $recurse = $filePattern -match '\*\*'
            
            # For patterns like ./template/**/*.txt, we need to handle ** specially
            if ($filePattern -match '\*\*/') {
                $basePath = $filePattern -replace '\*\*.*$', ''
                if (-not [System.IO.Path]::IsPathRooted($basePath)) {
                    $basePath = Join-Path (Get-Location) $basePath
                }
                $includePattern = $filePattern -replace '^.*\*\*/', '' -replace '^\*\*\\', ''
                
                if (Test-Path $basePath) {
                    Get-ChildItem -Path $basePath -Recurse -File | Where-Object {
                        $_.FullName -like "*$includePattern"
                    } | Where-Object {
                        & $shouldProcessFile $_.FullName
                    } | ForEach-Object {
                        $content = Get-Content -Path $_.FullName -Raw -Encoding UTF8
                        if ($content) {
                            $result = & $replaceInContent $content
                            if ($result.Success) {
                                Set-Content -Path $_.FullName -Value $result.Content -Encoding UTF8 -NoNewline
                                Write-Host "    ✓ $($_.FullName)" -ForegroundColor Green
                                $filesProcessed++
                            }
                        }
                    }
                }
            } elseif (Test-Path $parentPath) {
                Get-ChildItem -Path $parentPath -Filter $pattern -Recurse:$recurse -File -ErrorAction SilentlyContinue | Where-Object {
                    & $shouldProcessFile $_.FullName
                } | ForEach-Object {
                    $content = Get-Content -Path $_.FullName -Raw -Encoding UTF8
                    if ($content) {
                        $result = & $replaceInContent $content
                        if ($result.Success) {
                            Set-Content -Path $_.FullName -Value $result.Content -Encoding UTF8 -NoNewline
                            Write-Host "    ✓ $($_.FullName)" -ForegroundColor Green
                            $filesProcessed++
                        }
                    }
                }
            }
        } else {
            # Direct file path
            if ((Test-Path $resolvedPath) -and (& $shouldProcessFile $resolvedPath)) {
                $content = Get-Content -Path $resolvedPath -Raw -Encoding UTF8
                if ($content) {
                    $result = & $replaceInContent $content
                    if ($result.Success) {
                        Set-Content -Path $resolvedPath -Value $result.Content -Encoding UTF8 -NoNewline
                        Write-Host "    ✓ $resolvedPath" -ForegroundColor Green
                        $filesProcessed++
                    }
                }
            } else {
                if (-not (Test-Path $resolvedPath)) {
                    Write-Host "    ⚠ File not found: $resolvedPath" -ForegroundColor Yellow
                }
            }
        }
    }
    
    if ($filesProcessed -eq 0) {
        Write-Host "    ⚠ No files found to replace" -ForegroundColor Yellow
    } else {
        Write-Host "  ✓ Processed $filesProcessed file(s)" -ForegroundColor Green
    }
}
