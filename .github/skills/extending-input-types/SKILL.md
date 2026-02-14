---
name: extending-input-types
description: Create custom input type hooks to add new question types to the system (e.g., password input, date picker, numeric input)
---

# Skill: Extending Input Types

## Overview

This skill teaches AI agents how to create custom input type hooks to add new question types to the system (e.g., password input, date picker, numeric input).

---

## Input Type Hook Basics

### Hook File Structure

**Location**: `hooks/{input_type}.ps1`

**Required Function**: `Get-UserInput`

**Template**:

```powershell
# Input type: {type_name} ({description})

. "$PSScriptRoot/common.ps1"

function Get-UserInput {
    param(
        [string]$Question,
        [array]$Options = $null,    # Optional, for types with options
        [hashtable]$Answers
    )

    Write-Host ""
    $processedQuestion = Invoke-Replacement -Text $Question -Answers $Answers

    # Your input logic here

    return $userInput  # Must return a string
}
```

---

## Creating Custom Input Types

### Example 1: Password Input

**Requirement**: Secure password input (hidden characters)

**File**: `hooks/password.ps1`

```powershell
# Input type: password (secure password input)

. "$PSScriptRoot/common.ps1"

function Get-UserInput {
    param(
        [string]$Question,
        [hashtable]$Answers
    )

    Write-Host ""
    $processedQuestion = Invoke-Replacement -Text $Question -Answers $Answers

    # Use Read-Host with -AsSecureString for password input
    $securePassword = Read-Host $processedQuestion -AsSecureString

    # Convert to plain text (if needed for replacements)
    $ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)
    $password = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr)
    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr)

    return $password
}
```

**Usage in steps.json**:

```json
{
  "question_id": "db_password",
  "question": "Enter database password:",
  "input_type": "password"
}
```

**Result**: User types password, characters hidden as `***`

---

### Example 2: Numeric Input with Validation

**Requirement**: Accept only numeric input within a range

**File**: `hooks/number.ps1`

```powershell
# Input type: number (numeric input with validation)

. "$PSScriptRoot/common.ps1"

function Get-UserInput {
    param(
        [string]$Question,
        [hashtable]$Answers
    )

    Write-Host ""
    $processedQuestion = Invoke-Replacement -Text $Question -Answers $Answers

    do {
        $input = Read-Host $processedQuestion

        # Validate numeric input
        if ($input -match '^\d+$') {
            return $input
        }

        Write-Host "  Please enter a valid number." -ForegroundColor Yellow
    } while ($true)
}
```

**Usage**:

```json
{
  "question_id": "port",
  "question": "Enter port number:",
  "input_type": "number"
}
```

**Enhanced Version with Range**:

Extend steps.json to support custom properties:

```json
{
  "question_id": "port",
  "question": "Enter port number (1000-9999):",
  "input_type": "number",
  "min": 1000,
  "max": 9999
}
```

**Hook implementation**:

```powershell
function Get-UserInput {
    param(
        [string]$Question,
        [hashtable]$Answers,
        [int]$Min = 0,
        [int]$Max = [int]::MaxValue
    )

    Write-Host ""
    $processedQuestion = Invoke-Replacement -Text $Question -Answers $Answers

    do {
        $input = Read-Host $processedQuestion

        if ($input -match '^\d+$') {
            $number = [int]$input
            if ($number -ge $Min -and $number -le $Max) {
                return $input
            }
            Write-Host "  Number must be between $Min and $Max." -ForegroundColor Yellow
        } else {
            Write-Host "  Please enter a valid number." -ForegroundColor Yellow
        }
    } while ($true)
}
```

**Note**: You'll need to pass custom properties from generator.ps1. See "Advanced: Custom Properties" below.

---

### Example 3: Yes/No Confirmation

**Requirement**: Simple yes/no confirmation

**File**: `hooks/confirm.ps1`

```powershell
# Input type: confirm (yes/no confirmation)

. "$PSScriptRoot/common.ps1"

function Get-UserInput {
    param(
        [string]$Question,
        [hashtable]$Answers
    )

    Write-Host ""
    $processedQuestion = Invoke-Replacement -Text $Question -Answers $Answers

    do {
        Write-Host "$processedQuestion (yes/no): " -NoNewline
        $input = Read-Host

        $normalized = $input.ToLower().Trim()

        if ($normalized -eq 'yes' -or $normalized -eq 'y') {
            return 'Yes'
        }
        elseif ($normalized -eq 'no' -or $normalized -eq 'n') {
            return 'No'
        }

        Write-Host "  Please enter 'yes' or 'no'." -ForegroundColor Yellow
    } while ($true)
}
```

**Usage**:

```json
{
  "question_id": "use_typescript",
  "question": "Use TypeScript",
  "input_type": "confirm"
}
```

---

### Example 4: File Path Input with Validation

**Requirement**: Accept file path and validate it exists

**File**: `hooks/filepath.ps1`

```powershell
# Input type: filepath (file path input with validation)

. "$PSScriptRoot/common.ps1"

function Get-UserInput {
    param(
        [string]$Question,
        [hashtable]$Answers
    )

    Write-Host ""
    $processedQuestion = Invoke-Replacement -Text $Question -Answers $Answers

    do {
        $input = Read-Host $processedQuestion

        # Process placeholders in the input path
        $processedPath = Invoke-Replacement -Text $input -Answers $Answers

        # Resolve relative to absolute path
        if (-not [System.IO.Path]::IsPathRooted($processedPath)) {
            $processedPath = Join-Path (Get-Location) $processedPath
        }

        if (Test-Path $processedPath) {
            return $input  # Return original input, not processed path
        }

        Write-Host "  Path not found: $processedPath" -ForegroundColor Yellow
        Write-Host "  Please enter a valid file path." -ForegroundColor Yellow
    } while ($true)
}
```

**Usage**:

```json
{
  "question_id": "config_file",
  "question": "Enter path to config file:",
  "input_type": "filepath"
}
```

---

### Example 5: Multiple Line Input

**Requirement**: Accept multiple lines of text

**File**: `hooks/multiline.ps1`

```powershell
# Input type: multiline (multi-line text input)

. "$PSScriptRoot/common.ps1"

function Get-UserInput {
    param(
        [string]$Question,
        [hashtable]$Answers
    )

    Write-Host ""
    $processedQuestion = Invoke-Replacement -Text $Question -Answers $Answers
    Write-Host $processedQuestion -ForegroundColor Cyan
    Write-Host "  (Enter text, type 'END' on a new line to finish)" -ForegroundColor Gray

    $lines = @()

    do {
        $line = Read-Host
        if ($line -eq 'END') {
            break
        }
        $lines += $line
    } while ($true)

    # Join with newlines
    return ($lines -join "`n")
}
```

**Usage**:

```json
{
  "question_id": "description",
  "question": "Enter project description:",
  "input_type": "multiline"
}
```

---

### Example 6: Dropdown Menu (Enhanced Select)

**Requirement**: Scrollable menu with arrow key navigation

**File**: `hooks/menu.ps1`

```powershell
# Input type: menu (interactive menu with arrow keys)
# Note: This is a conceptual example. Full implementation requires
# more complex console manipulation.

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

    $selectedIndex = 0

    # Display menu and handle arrow keys
    # This is a simplified version
    for ($i = 0; $i -lt $processedOptions.Count; $i++) {
        if ($i -eq $selectedIndex) {
            Write-Host "  > $($processedOptions[$i])" -ForegroundColor Green
        } else {
            Write-Host "    $($processedOptions[$i])"
        }
    }

    # For simplicity, fall back to numbered selection
    do {
        $choice = Read-Host "Select option (1-$($processedOptions.Count))"
        if ([int]$choice -ge 1 -and [int]$choice -le $processedOptions.Count) {
            return $processedOptions[[int]$choice - 1]
        }
        Write-Host "  Invalid selection." -ForegroundColor Yellow
    } while ($true)
}
```

---

## Advanced: Custom Properties

To pass custom properties from steps.json to your hook:

### 1. Modify generator.ps1 (Optional)

Current implementation in `generator.ps1`:

```powershell
# Call Get-UserInput (pass Options if available)
if ($step.options) {
    $answer = Get-UserInput -Question $step.question -Options $step.options -Answers $answers
} else {
    $answer = Get-UserInput -Question $step.question -Answers $answers
}
```

**Enhanced version** to pass entire step object:

```powershell
# Pass entire step object to allow custom properties
$answer = Get-UserInput -Question $step.question -Options $step.options -Step $step -Answers $answers
```

### 2. Update Hook to Accept Step Object

```powershell
function Get-UserInput {
    param(
        [string]$Question,
        [array]$Options = $null,
        [object]$Step = $null,    # NEW: Full step object
        [hashtable]$Answers
    )

    # Access custom properties
    $min = if ($Step.min) { $Step.min } else { 0 }
    $max = if ($Step.max) { $Step.max } else { [int]::MaxValue }

    # Your logic here
}
```

### 3. Use Custom Properties in steps.json

```json
{
  "question_id": "port",
  "question": "Enter port:",
  "input_type": "number",
  "min": 1000,
  "max": 9999,
  "default": 3000
}
```

**Note**: This requires modifying `generator.ps1`, which should be done carefully.

---

## Naming Conventions

### File Names

- Lowercase, no spaces: `password.ps1`, `multiline.ps1`
- Match `input_type` value exactly
- Use descriptive names: `filepath.ps1` not `path.ps1`

### Function Names

- Always `Get-UserInput` (exact name)
- Case matters in PowerShell

### Variable Names

- Use PascalCase: `$ProcessedQuestion`, `$UserInput`
- Be consistent with existing hooks

---

## Hook Development Checklist

When creating a new input type hook:

- [ ] Create file `hooks/{type}.ps1`
- [ ] Source `common.ps1` at the top
- [ ] Define `Get-UserInput` function
- [ ] Accept required parameters: `$Question`, `$Answers`
- [ ] Accept `$Options` if it's a selection type
- [ ] Process question text with `Invoke-Replacement`
- [ ] Process options with `Invoke-Replacement` (if applicable)
- [ ] Implement input validation
- [ ] Provide clear error messages
- [ ] Return a string value
- [ ] Test with test configuration file
- [ ] Document in README.md
- [ ] Add usage examples

---

## Testing Input Types

### Test Configuration

Create `test-input-types.json`:

```json
{
  "steps": [
    {
      "question_id": "password",
      "question": "Enter password:",
      "input_type": "password",
      "actions": [
        {
          "type": "execute",
          "command": "Write-Host 'Password length: ' ([[[ANS:password]]]).Length"
        }
      ]
    },
    {
      "question_id": "port",
      "question": "Enter port:",
      "input_type": "number",
      "actions": [
        {
          "type": "execute",
          "command": "Write-Host 'Port: [[[ANS:port]]]'"
        }
      ]
    },
    {
      "question_id": "confirmed",
      "question": "Confirm setup",
      "input_type": "confirm",
      "actions": [
        {
          "type": "execute",
          "command": "Write-Host 'User confirmed: [[[ANS:confirmed]]]'"
        }
      ]
    }
  ]
}
```

Run:

```powershell
.\generator.ps1 -StepPath "test-input-types.json"
```

---

## Common Mistakes

### 1. Wrong Function Name

❌ **Wrong:**

```powershell
function Get-Input {  # Wrong name!
    param([string]$Question, [hashtable]$Answers)
    return Read-Host $Question
}
```

✅ **Correct:**

```powershell
function Get-UserInput {  # Exact name required
    param([string]$Question, [hashtable]$Answers)
    return Read-Host $Question
}
```

### 2. Not Processing Placeholders

❌ **Wrong:**

```powershell
function Get-UserInput {
    param([string]$Question, [hashtable]$Answers)
    return Read-Host $Question  # Question not processed!
}
```

✅ **Correct:**

```powershell
function Get-UserInput {
    param([string]$Question, [hashtable]$Answers)
    $processedQuestion = Invoke-Replacement -Text $Question -Answers $Answers
    return Read-Host $processedQuestion
}
```

### 3. Not Sourcing common.ps1

❌ **Wrong:**

```powershell
# Missing: . "$PSScriptRoot/common.ps1"

function Get-UserInput {
    param([string]$Question, [hashtable]$Answers)
    $processedQuestion = Invoke-Replacement -Text $Question -Answers $Answers  # Function not available!
    return Read-Host $processedQuestion
}
```

✅ **Correct:**

```powershell
. "$PSScriptRoot/common.ps1"  # Load common functions

function Get-UserInput {
    param([string]$Question, [hashtable]$Answers)
    $processedQuestion = Invoke-Replacement -Text $Question -Answers $Answers
    return Read-Host $processedQuestion
}
```

### 4. Returning Non-String

❌ **Wrong:**

```powershell
function Get-UserInput {
    param([string]$Question, [hashtable]$Answers)
    $number = Read-Host $Question
    return [int]$number  # Returns integer!
}
```

✅ **Correct:**

```powershell
function Get-UserInput {
    param([string]$Question, [hashtable]$Answers)
    $number = Read-Host $Question
    return $number  # Returns string
}
```

---

## Best Practices

1. ✅ Always source `common.ps1` first
2. ✅ Process question text with `Invoke-Replacement`
3. ✅ Process options with `Invoke-Replacement` (if applicable)
4. ✅ Return string values only
5. ✅ Provide validation with clear error messages
6. ✅ Use consistent color scheme (see Coding Best Practices)
7. ✅ Add blank line before question with `Write-Host ""`
8. ✅ Test with various placeholder combinations
9. ✅ Handle edge cases (empty input, special characters)
10. ✅ Document usage in README.md

---

## Complete Example: URL Input with Validation

**File**: `hooks/url.ps1`

```powershell
# Input type: url (URL input with validation)

. "$PSScriptRoot/common.ps1"

function Get-UserInput {
    param(
        [string]$Question,
        [hashtable]$Answers
    )

    Write-Host ""
    $processedQuestion = Invoke-Replacement -Text $Question -Answers $Answers

    do {
        $input = Read-Host $processedQuestion

        # Validate URL format
        if ($input -match '^https?://[^\s/$.?#].[^\s]*$') {
            return $input
        }

        Write-Host "  Please enter a valid URL (http:// or https://)." -ForegroundColor Yellow
    } while ($true)
}
```

**Usage**:

```json
{
  "question_id": "api_url",
  "question": "Enter API URL:",
  "input_type": "url",
  "actions": [
    {
      "type": "replace",
      "files": ["./config.json"],
      "target": "\"api_url\": \"\"",
      "value": "\"api_url\": \"[[[ANS:api_url]]]\""
    }
  ]
}
```
