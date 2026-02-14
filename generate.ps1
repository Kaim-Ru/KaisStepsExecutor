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
        
        if ($Answers[$questionId] -ne $expectedAns) {
            return $false
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
    
    # Process target and value with placeholder replacement
    $target = Invoke-Replacement -Text $Action.target -Answers $Answers
    $value = Invoke-Replacement -Text $Action.value -Answers $Answers
    
    $filesProcessed = 0
    
    foreach ($filePattern in $Action.files) {
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
                    } | ForEach-Object {
                        $content = Get-Content -Path $_.FullName -Raw -Encoding UTF8
                        if ($content -and $content.Contains($target)) {
                            $newContent = $content.Replace($target, $value)
                            # Process any remaining placeholders (like UUIDv4) in the content
                            $newContent = Invoke-Replacement -Text $newContent -Answers $Answers
                            Set-Content -Path $_.FullName -Value $newContent -Encoding UTF8 -NoNewline
                            Write-Host "    ✓ $($_.FullName)" -ForegroundColor Green
                            $filesProcessed++
                        }
                    }
                }
            } elseif (Test-Path $parentPath) {
                Get-ChildItem -Path $parentPath -Filter $pattern -Recurse:$recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
                    $content = Get-Content -Path $_.FullName -Raw -Encoding UTF8
                    if ($content -and $content.Contains($target)) {
                        $newContent = $content.Replace($target, $value)
                        # Process any remaining placeholders (like UUIDv4) in the content
                        $newContent = Invoke-Replacement -Text $newContent -Answers $Answers
                        Set-Content -Path $_.FullName -Value $newContent -Encoding UTF8 -NoNewline
                        Write-Host "    ✓ $($_.FullName)" -ForegroundColor Green
                        $filesProcessed++
                    }
                }
            }
        } else {
            # Direct file path
            if (Test-Path $resolvedPath) {
                $content = Get-Content -Path $resolvedPath -Raw -Encoding UTF8
                if ($content -and $content.Contains($target)) {
                    $newContent = $content.Replace($target, $value)
                    # Process any remaining placeholders (like UUIDv4) in the content
                    $newContent = Invoke-Replacement -Text $newContent -Answers $Answers
                    Set-Content -Path $resolvedPath -Value $newContent -Encoding UTF8 -NoNewline
                    Write-Host "    ✓ $resolvedPath" -ForegroundColor Green
                    $filesProcessed++
                }
            } else {
                Write-Host "    ⚠ File not found: $resolvedPath" -ForegroundColor Yellow
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
    
    # If destination is a directory, create symlink inside it
    if (Test-Path $destination -PathType Container) {
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
    Write-Host "  PowerShell Steps Executor" -ForegroundColor Cyan
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Process each step
    $stepNumber = 0
    foreach ($step in $config.steps) {
        $stepNumber++
        
        Write-Host "--- Step $stepNumber ---" -ForegroundColor Yellow
        
        # Ask question if question_id exists
        if ($step.question_id) {
            $stepType = if ($step.type) { $step.type } else { "input" }
            $options = if ($step.options) { $step.options } else { @() }
            
            $answer = Get-UserInput -Question $step.question -Type $stepType -Options $options
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
                    default {
                        Write-Host "  [Warning] Unknown action type: $($action.type)" -ForegroundColor Yellow
                    }
                }
            }
        }
        
        Write-Host ""
    }
    
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "  ✓ All steps completed successfully!" -ForegroundColor Green
    Write-Host "==========================================" -ForegroundColor Cyan
    
} catch {
    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Red
    Write-Host "  ✗ An error occurred" -ForegroundColor Red
    Write-Host "==========================================" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}
