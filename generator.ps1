param(
    [Parameter(Mandatory=$true)]
    [string]$StepPath
)

# Load common utilities
. "$PSScriptRoot/hooks/common.ps1"

# Utility functions
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

function Find-HookFile {
    param(
        [string]$HookName
    )
    
    # Priority 1: Try builtin directory (hooks/builtin/hookname.ps1)
    $builtinPath = "$PSScriptRoot/hooks/builtin/$HookName.ps1"
    if (Test-Path $builtinPath) {
        return $builtinPath
    }
    
    # Priority 2: Try direct path (hooks/hookname.ps1) for backward compatibility
    $directPath = "$PSScriptRoot/hooks/$HookName.ps1"
    if (Test-Path $directPath) {
        return $directPath
    }
    
    # Priority 3: Search recursively in hooks/ for custom hooks
    $foundFiles = Get-ChildItem -Path "$PSScriptRoot/hooks" -Filter "$HookName.ps1" -Recurse -File -ErrorAction SilentlyContinue
    
    if ($foundFiles.Count -eq 0) {
        return $null
    }
    
    if ($foundFiles.Count -gt 1) {
        Write-Host "  [Warning] Multiple hook files found for '$HookName'. Using first match: $($foundFiles[0].FullName)" -ForegroundColor Yellow
    }
    
    return $foundFiles[0].FullName
}

# Main script
try {
    if (-not (Test-Path $StepPath)) {
        Write-Host "Error: $StepPath not found" -ForegroundColor Red
        exit 1
    }
    
    $config = Get-Content -Path $StepPath -Raw -Encoding UTF8 | ConvertFrom-Json
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
            
            # Load input type hook
            $hookPath = Find-HookFile -HookName $stepType
            if (-not $hookPath) {
                Write-Host "  [Warning] Hook not found for input type '$stepType'" -ForegroundColor Yellow
                Write-Host "  Skipping this question." -ForegroundColor Yellow
                continue
            }
            
            # Dot-source the hook to load Get-UserInput function
            . $hookPath
            
            # Call Get-UserInput (pass Options if available)
            if ($step.options) {
                $answer = Get-UserInput -Question $step.question -Options $step.options -Answers $answers
            } else {
                $answer = Get-UserInput -Question $step.question -Answers $answers
            }
            
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
                
                # Validate action type exists
                if (-not $action.type) {
                    Write-Host "  [Warning] Action type is missing" -ForegroundColor Yellow
                    continue
                }
                
                # Load action type hook
                $hookPath = Find-HookFile -HookName $action.type
                if (-not $hookPath) {
                    Write-Host "  [Warning] Hook not found for action type '$($action.type)'" -ForegroundColor Yellow
                    Write-Host "  Skipping this action." -ForegroundColor Yellow
                    continue
                }
                
                # Dot-source the hook to load Invoke-*Action function
                . $hookPath
                
                # Build function name dynamically (e.g., "execute" -> "Invoke-ExecuteAction")
                $functionName = "Invoke-" + (Get-Culture).TextInfo.ToTitleCase($action.type) + "Action"
                
                # Call the action function
                & $functionName -Action $action -Answers $answers
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
