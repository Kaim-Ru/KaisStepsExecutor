# Input type: input (text input)

. "$PSScriptRoot/../common.ps1"

function Get-UserInput {
    param(
        [string]$Question,
        [hashtable]$Answers
    )
    
    Write-Host ""
    $processedQuestion = Invoke-Replacement -Text $Question -Answers $Answers
    return Read-Host $processedQuestion
}
