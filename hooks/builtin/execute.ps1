# Action type: execute (run PowerShell command)

. "$PSScriptRoot/../common.ps1"

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
