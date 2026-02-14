# Input type: demo-custom-placeholders
# Demonstrates how to register custom placeholders without modifying common.ps1

. "$PSScriptRoot/../common.ps1"

# Register custom placeholders that will be available in all subsequent steps
# These are just examples - you can create any placeholder you need!

# Example 1: Timestamp placeholder
Register-Placeholder -Name "TIMESTAMP" -ScriptBlock {
    param($Answers)
    return Get-Date -Format "yyyyMMdd_HHmmss"
}

# Example 2: Username placeholder
Register-Placeholder -Name "CURRENT_USER" -ScriptBlock {
    param($Answers)
    return $env:USERNAME
}

# Example 3: Transform answer to uppercase
Register-Placeholder -Name "PROJECT_UPPER" -ScriptBlock {
    param($Answers)
    if ($Answers.ContainsKey("project_name")) {
        return $Answers["project_name"].ToUpper()
    }
    return ""
}

# Example 4: Transform answer to lowercase with hyphens
Register-Placeholder -Name "PROJECT_SLUG" -ScriptBlock {
    param($Answers)
    if ($Answers.ContainsKey("project_name")) {
        # Convert to lowercase and replace spaces with hyphens
        return $Answers["project_name"].ToLower() -replace '\s+', '-'
    }
    return ""
}

# Example 5: Combine multiple answers
Register-Placeholder -Name "FULL_PATH" -ScriptBlock {
    param($Answers)
    $name = $Answers["project_name"]
    $category = $Answers["category"]
    if ($name -and $category) {
        return "./${category}/${name}"
    }
    return "."
}

function Get-UserInput {
    param(
        [string]$Question,
        [hashtable]$Answers
    )
    
    Write-Host ""
    Write-Host "Custom placeholders registered successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "The following placeholders are now available:" -ForegroundColor Cyan
    Write-Host "  - [[[TIMESTAMP]]]      : Current timestamp (yyyyMMdd_HHmmss)" -ForegroundColor White
    Write-Host "  - [[[CURRENT_USER]]]   : Current Windows username" -ForegroundColor White
    Write-Host "  - [[[PROJECT_UPPER]]]  : Project name in UPPERCASE" -ForegroundColor White
    Write-Host "  - [[[PROJECT_SLUG]]]   : Project name in lowercase-with-hyphens" -ForegroundColor White
    Write-Host "  - [[[FULL_PATH]]]      : Combined path from category and project name" -ForegroundColor White
    Write-Host ""
    Write-Host "Try using these placeholders in the next steps!" -ForegroundColor Yellow
    Write-Host ""
    
    # Just return a dummy value - this hook is for demonstration
    return ""
}
