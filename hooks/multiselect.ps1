# Input type: multiselect (multiple selection from options)
# Example custom hook

. "$PSScriptRoot/common.ps1"

function Get-UserInput {
    param(
        [string]$Question,
        [array]$Options,
        [hashtable]$Answers
    )
    
    Write-Host ""
    $processedQuestion = Invoke-Replacement -Text $Question -Answers $Answers
    Write-Host $processedQuestion -ForegroundColor Cyan
    
    # Process options with placeholders
    $processedOptions = @()
    foreach ($option in $Options) {
        $processedOptions += Invoke-Replacement -Text $option -Answers $Answers
    }
    
    # Display options
    for ($i = 0; $i -lt $processedOptions.Count; $i++) {
        Write-Host "  $($i + 1). $($processedOptions[$i])"
    }
    
    # Get and validate multiple selections
    Write-Host "  (Enter numbers separated by spaces, e.g., '1 3 4')" -ForegroundColor Gray
    do {
        $userInput = Read-Host "Select options (1-$($processedOptions.Count))"
        $selections = $userInput -split '\s+' | Where-Object { $_ -match '^\d+$' } | ForEach-Object { [int]$_ }
        
        $valid = $true
        $selectedItems = @()
        
        foreach ($sel in $selections) {
            if ($sel -lt 1 -or $sel -gt $processedOptions.Count) {
                $valid = $false
                break
            }
            $selectedItems += $processedOptions[$sel - 1]
        }
        
        if ($valid -and $selectedItems.Count -gt 0) {
            # Return comma-separated values
            return ($selectedItems -join ', ')
        }
        
        Write-Host "  Invalid selection. Please try again." -ForegroundColor Yellow
    } while ($true)
}
