param(
    [string]$ConfigPath = "steps.json"
)

# Utility functions
function Invoke-Replacement {
    param(
        [string]$Text,
        [hashtable]$Answers
    )
    
    $result = $Text
    
    # Replace [[[ANS:question_id]]]
    foreach ($key in $Answers.Keys) {
        $placeholder = "[[[ANS:$key]]]"
        $result = $result -replace [regex]::Escape($placeholder), [regex]::Escape($Answers[$key])
    }
    
    # Replace [[[UUIDv4]]] with a new UUID
    while ($result.Contains("[[[UUIDv4]]]")) {
        $newUUID = [guid]::NewGuid().ToString()
        # Replace only the first occurrence
        $index = $result.IndexOf("[[[UUIDv4]]]")
        $result = $result.Substring(0, $index) + $newUUID + $result.Substring($index + "[[[UUIDv4]]]".Length)
    }
    
    # Unescape \\[[[ to \[[[ and then \[[[ to [[[
    # In JSON, \\[[[ becomes \[[[ after parsing
    # We need to unescape \[[[ to [[[
    $result = $result -replace '\\(\[\[\[)', '$1'
    
    return $result
}

function Test-Conditions {
    param(
        [array]$Conditions,
        [hashtable]$Answers
    )
    
    if (-not $Conditions -or $Conditions.Count -eq 0) {
        return $true
    }
    
    foreach ($condition in $Conditions) {
        $questionId = $condition.question_id
        $expectedAns = $condition.ans
        
        # Check if expectedAns is a regex object
        if ($expectedAns -is [PSCustomObject] -and $expectedAns.regex) {
            # Regex matching - process placeholders in regex pattern
            $processedRegex = Invoke-Replacement -Text $expectedAns.regex -Answers $Answers
            $userAnswer = $Answers[$questionId]
            if (-not ($userAnswer -match $processedRegex)) {
                return $false
            }
        }
        # Check if expectedAns is an array
        elseif ($expectedAns -is [array]) {
            # If it's an array, check if the answer matches any of the values
            $match = $false
            foreach ($value in $expectedAns) {
                # Process placeholders in each value
                $processedValue = Invoke-Replacement -Text $value -Answers $Answers
                if ($Answers[$questionId] -eq $processedValue) {
                    $match = $true
                    break
                }
            }
            if (-not $match) {
                return $false
            }
        } else {
            # Single value comparison - process placeholders
            $processedAns = Invoke-Replacement -Text $expectedAns -Answers $Answers
            if ($Answers[$questionId] -ne $processedAns) {
                return $false
            }
        }
    }
    
    return $true
}

function Get-UserInput {
    param(
        [string]$Question,
        [string]$Type = "input",
        [array]$Options = @()
    )
    
    if ($Type -eq "select") {
        Write-Host ""
        Write-Host $Question -ForegroundColor Cyan
        for ($i = 0; $i -lt $Options.Count; $i++) {
            Write-Host "  $($i + 1). $($Options[$i])"
        }
        
        do {
            $choice = Read-Host "Please select (1-$($Options.Count))"
            if ([int]$choice -ge 1 -and [int]$choice -le $Options.Count) {
                return $Options[[int]$choice - 1]
            }
            Write-Host "  Invalid selection. Please try again." -ForegroundColor Yellow
        } while ($true)
    } else {
        Write-Host ""
        return Read-Host $Question
    }
}

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

# Action handlers
function Invoke-ExecuteAction {
    param(
        [object]$Action,
        [hashtable]$Answers
    )
    
    Write-Host "  [Execute] Running command..." -ForegroundColor Cyan
    
    $command = Invoke-Replacement -Text $Action.command -Answers $Answers
    Write-Host "  > $command" -ForegroundColor Gray
    
    try {
        Invoke-Expression $command
        Write-Host "  ✓ Execution completed" -ForegroundColor Green
    } catch {
        Write-Host "  ✗ Error: $_" -ForegroundColor Red
        throw
    }
}

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

# Main script
try {
    if (-not (Test-Path $ConfigPath)) {
        Write-Host "Error: $ConfigPath not found" -ForegroundColor Red
        exit 1
    }
    
    $config = Get-Content -Path $ConfigPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $answers = @{}
    
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "  　　　　　 KaisStepsExecutor" -ForegroundColor Cyan
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Process each step
    $stepNumber = 0
    foreach ($step in $config.steps) {
        $stepNumber++
        
        Write-Host "--- Step $stepNumber ---" -ForegroundColor Yellow
        
        # Ask question if question_id exists
        if ($step.question_id) {
            $stepType = if ($step.input_type) { $step.input_type } else { "input" }
            
            # Validate step type
            $validStepTypes = @("input", "select")
            if ($step.input_type -and $stepType -notin $validStepTypes) {
                Write-Host "  [Warning] Invalid question type: '$stepType'. Valid types are: $($validStepTypes -join ', ')" -ForegroundColor Yellow
                Write-Host "  Using 'input' as default." -ForegroundColor Yellow
                $stepType = "input"
            }
            
            # Process question text with placeholders
            $processedQuestion = Invoke-Replacement -Text $step.question -Answers $answers
            
            # Process options with placeholders
            $processedOptions = @()
            if ($step.options) {
                foreach ($option in $step.options) {
                    $processedOptions += Invoke-Replacement -Text $option -Answers $answers
                }
            }
            
            $answer = Get-UserInput -Question $processedQuestion -Type $stepType -Options $processedOptions
            $answers[$step.question_id] = $answer
            Write-Host "  Answer saved: '$answer'" -ForegroundColor Green
            Write-Host ""
        }
        
        # Process actions
        if ($step.actions) {
            foreach ($action in $step.actions) {
                # Check conditions
                if (-not (Test-Conditions -Conditions $action.conditions -Answers $answers)) {
                    Write-Host "  [Skip] Conditions not met" -ForegroundColor Yellow
                    continue
                }
                
                # Validate action type
                $validActionTypes = @("execute", "replace", "copy", "symlink")
                if (-not $action.type) {
                    Write-Host "  [Warning] Action type is missing" -ForegroundColor Yellow
                    continue
                }
                if ($action.type -notin $validActionTypes) {
                    Write-Host "  [Warning] Unknown action type: '$($action.type)'. Valid types are: $($validActionTypes -join ', ')" -ForegroundColor Yellow
                    continue
                }
                
                # Execute action based on type
                switch ($action.type) {
                    "execute" {
                        Invoke-ExecuteAction -Action $action -Answers $answers
                    }
                    "replace" {
                        Invoke-ReplaceAction -Action $action -Answers $answers
                    }
                    "copy" {
                        Invoke-CopyAction -Action $action -Answers $answers
                    }
                    "symlink" {
                        Invoke-SymlinkAction -Action $action -Answers $answers
                    }
                }
            }
        }
        
        Write-Host ""
    }
    
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "   ✓ All steps completed successfully!" -ForegroundColor Green
    Write-Host "==========================================" -ForegroundColor Cyan
    
} catch {
    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Red
    Write-Host "           ✗ An error occurred" -ForegroundColor Red
    Write-Host "==========================================" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}
