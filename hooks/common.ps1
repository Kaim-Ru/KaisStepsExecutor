# Common utilities for hook scripts

# Global registry for custom placeholders
# Each entry: key = placeholder name (e.g., "TIMESTAMP"), value = scriptblock to generate the value
if (-not $global:CustomPlaceholders) {
    $global:CustomPlaceholders = @{}
}

<#
.SYNOPSIS
    Register a custom placeholder that can be used anywhere in the workflow.

.DESCRIPTION
    This function allows hook scripts to register custom placeholders without modifying common.ps1.
    The placeholder will be available as [[[PLACEHOLDER_NAME]]] in any text, file path, or command.

.PARAMETER Name
    The name of the placeholder (without [[[  ]]] brackets).
    Example: "TIMESTAMP" will create placeholder [[[TIMESTAMP]]]

.PARAMETER ScriptBlock
    A scriptblock that generates the placeholder value.
    The scriptblock receives a hashtable of $Answers as its parameter.
    Example: { param($Answers) return (Get-Date -Format "yyyyMMdd") }

.EXAMPLE
    Register-Placeholder -Name "TIMESTAMP" -ScriptBlock { param($Answers) return (Get-Date -Format "yyyyMMdd_HHmmss") }
    # Now [[[TIMESTAMP]]] can be used anywhere and will be replaced with current timestamp

.EXAMPLE
    Register-Placeholder -Name "UPPER_NAME" -ScriptBlock { param($Answers) return $Answers["project_name"].ToUpper() }
    # Converts the project_name answer to uppercase
#>
function Register-Placeholder {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Name,
        
        [Parameter(Mandatory=$true)]
        [scriptblock]$ScriptBlock
    )
    
    $global:CustomPlaceholders[$Name] = $ScriptBlock
    Write-Verbose "Registered custom placeholder: [[[${Name}]]]"
}

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
    
    # Replace custom placeholders registered by hooks
    foreach ($placeholderName in $global:CustomPlaceholders.Keys) {
        $placeholder = "[[[${placeholderName}]]]"
        if ($result.Contains($placeholder)) {
            try {
                # Execute the scriptblock to get the value
                $value = & $global:CustomPlaceholders[$placeholderName] $Answers
                $result = $result.Replace($placeholder, $value)
            }
            catch {
                Write-Host "  [Warning] Failed to process custom placeholder [[[${placeholderName}]]]: $_" -ForegroundColor Yellow
            }
        }
    }
    
    # Replace [[[UUIDv4]]] with a new UUID
    while ($result.Contains("[[[UUIDv4]]]")) {
        $newUUID = [guid]::NewGuid().ToString()
        # Replace only the first occurrence
        $index = $result.IndexOf("[[[UUIDv4]]]")
        $result = $result.Substring(0, $index) + $newUUID + $result.Substring($index + "[[[UUIDv4]]]".Length)
    }
    
    # Expand environment variables like %AppData%, %USERPROFILE%, etc.
    $result = [Environment]::ExpandEnvironmentVariables($result)
    
    # Unescape \\[[[ to \[[[ and then \[[[ to [[[
    # In JSON, \\[[[ becomes \[[[ after parsing
    # We need to unescape \[[[ to [[[
    $result = $result -replace '\\(\[\[\[)', '$1'
    
    return $result
}
