# Input type: select (single selection from options)

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
    
    # Get and validate selection
    do {
        $choice = Read-Host "Please select (1-$($processedOptions.Count))"
        if ([int]$choice -ge 1 -and [int]$choice -le $processedOptions.Count) {
            return $processedOptions[[int]$choice - 1]
        }
        Write-Host "  Invalid selection. Please try again." -ForegroundColor Yellow
    } while ($true)
}
