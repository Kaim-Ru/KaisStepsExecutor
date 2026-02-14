---
name: working-with-placeholders
description: Use the placeholder system for dynamic value insertion and extend it with custom placeholder types
---

# Skill: Working with Placeholders

## Overview

This skill teaches AI agents how to use the placeholder system for dynamic value insertion and how to add new placeholder types to the system.

---

## Placeholder Basics

Placeholders use the format `[[[PLACEHOLDER_NAME]]]` and are processed by the `Invoke-Replacement` function in `hooks/common.ps1`.

### Where Placeholders Work

Placeholders are processed in:

- `question` (question text)
- `options` (selection options)
- `command` (execute command)
- `target` and `value` (replace action)
- `source` and `destination` (copy/symlink/mkdir actions)
- `ans` in `conditions` (condition values)
- File content during replace operations

---

## Built-in Placeholders

### 1. [[[ANS:question_id]]] - Answer Reference

References the user's answer to a previous question.

**Basic Usage:**

```json
{
  "steps": [
    {
      "question_id": "project_name",
      "question": "Enter project name:",
      "input_type": "input"
    },
    {
      "actions": [
        {
          "type": "execute",
          "command": "Write-Host 'Creating project: [[[ANS:project_name]]]'"
        }
      ]
    }
  ]
}
```

**In File Operations:**

```json
{
  "type": "copy",
  "source": "./template",
  "destination": "./[[[ANS:project_name]]]/"
}
```

**In Replace Operations:**

```json
{
  "type": "replace",
  "files": ["./template/**/*.txt"],
  "target": "[[[PROJECT_NAME]]]",
  "value": "[[[ANS:project_name]]]"
}
```

**Multiple References:**

```json
{
  "type": "execute",
  "command": "Write-Host '[[[ANS:name]]] is working on [[[ANS:project]]]'"
}
```

**In Question Text:**

```json
{
  "question_id": "confirm",
  "question": "Create project '[[[ANS:project_name]]]'? (yes/no)",
  "input_type": "input"
}
```

**In Options:**

```json
{
  "question_id": "choose_path",
  "question": "Where to create the project?",
  "input_type": "select",
  "options": [
    "./[[[ANS:project_name]]]",
    "./projects/[[[ANS:project_name]]]",
    "D:/Development/[[[ANS:project_name]]]"
  ]
}
```

**In Conditions:**

```json
{
  "type": "execute",
  "command": "Write-Host 'Names match!'",
  "conditions": [
    { "question_id": "confirm_name", "ans": "[[[ANS:project_name]]]" }
  ]
}
```

### 2. [[[UUIDv4]]] - UUID Generation

Generates a unique UUID v4 for each occurrence. Each placeholder generates a different UUID.

**Basic Usage:**

```json
{
  "type": "replace",
  "files": ["./config.json"],
  "target": "\"app_id\": \"\"",
  "value": "\"app_id\": \"[[[UUIDv4]]]\""
}
```

**Multiple UUIDs:**

```json
{
  "type": "replace",
  "files": ["./config.json"],
  "target": "[[[TEMPLATE]]]",
  "value": "{ \"app_id\": \"[[[UUIDv4]]]\", \"session_id\": \"[[[UUIDv4]]]\" }"
}
```

**Result Example:**

```json
{
  "app_id": "550e8400-e29b-41d4-a716-446655440000",
  "session_id": "6ba7b810-9dad-11d1-80b4-00c04fd430c8"
}
```

Each `[[[UUIDv4]]]` is replaced with a different UUID.

**In File Names (via execute):**

```json
{
  "type": "execute",
  "command": "New-Item -ItemType File -Path './logs/session_[[[UUIDv4]]].log'"
}
```

---

## Escaping Placeholders

To output a placeholder as literal text (without replacement), escape it with a backslash.

### JSON Escaping Rules

In JSON, backslashes must be escaped: `\\` becomes `\`

**To output literal `[[[ANS:name]]]`:**

```json
{
  "type": "replace",
  "target": "[[[EXAMPLE]]]",
  "value": "\\[[[ANS:name]]]"
}
```

**Processing:**

1. JSON parsing: `\\[[[ANS:name]]]` → `\[[[ANS:name]]]`
2. Placeholder processing: `\[[[ANS:name]]]` → `[[[ANS:name]]]`
3. Result in file: `[[[ANS:name]]]` (literal text)

### Escaping Examples

**Example 1: Documentation Template**

```json
{
  "type": "replace",
  "files": ["./README.md"],
  "target": "[[[USAGE_EXAMPLE]]]",
  "value": "To use placeholders, write \\[[[ANS:variable]]] in your config."
}
```

**Result in README.md:**

```
To use placeholders, write [[[ANS:variable]]] in your config.
```

**Example 2: Code Generation**

```json
{
  "type": "replace",
  "files": ["./generator.js"],
  "target": "[[[CODE]]]",
  "value": "const pattern = /\\[[[\\w:]+]]]/g;"
}
```

**Result:**

```javascript
const pattern = /[[[w:]+]]]/g;
```

---

## Advanced Usage Patterns

### Pattern 1: Nested Placeholders (Not Directly Supported)

You cannot nest placeholders like `[[[ANS:[[[ANS:id]]]]]]`.

**Workaround**: Use multiple steps:

```json
{
  "steps": [
    {
      "question_id": "var_name",
      "question": "Enter variable name:",
      "input_type": "input"
    },
    {
      "question_id": "var_value",
      "question": "Enter value for '[[[ANS:var_name]]]':",
      "input_type": "input"
    },
    {
      "actions": [
        {
          "type": "execute",
          "command": "Write-Host '[[[ANS:var_name]]] = [[[ANS:var_value]]]'"
        }
      ]
    }
  ]
}
```

### Pattern 2: Combining Multiple Answers

```json
{
  "type": "replace",
  "files": ["./package.json"],
  "target": "\"name\": \"\"",
  "value": "\"name\": \"@[[[ANS:scope]]]/[[[ANS:package_name]]]\""
}
```

If user enters:

- scope: `mycompany`
- package_name: `awesome-lib`

Result:

```json
"name": "@mycompany/awesome-lib"
```

### Pattern 3: Conditional Replacement Based on Answer

```json
{
  "actions": [
    {
      "type": "replace",
      "files": ["./config.txt"],
      "target": "[[[ENV]]]",
      "value": "development",
      "conditions": [{ "question_id": "environment", "ans": "dev" }]
    },
    {
      "type": "replace",
      "files": ["./config.txt"],
      "target": "[[[ENV]]]",
      "value": "production",
      "conditions": [{ "question_id": "environment", "ans": "prod" }]
    }
  ]
}
```

### Pattern 4: Path Construction

```json
{
  "type": "copy",
  "source": "./template",
  "destination": "./projects/[[[ANS:category]]]/[[[ANS:project_name]]]/"
}
```

If user enters:

- category: `web-apps`
- project_name: `my-blog`

Result: `./projects/web-apps/my-blog/`

---

## Adding Custom Placeholders

The system supports two methods for adding custom placeholders:

1. **Dynamic Registration (Recommended)**: Register placeholders from any hook file without modifying `common.ps1`
2. **Direct Implementation (Legacy)**: Modify `Invoke-Replacement` function in `common.ps1`

---

### Method 1: Dynamic Registration (Recommended)

**Available since**: v2.0

Use the `Register-Placeholder` function to dynamically add custom placeholders from any hook file.

#### Basic Usage

```powershell
# In any hook file (e.g., hooks/myhook.ps1)
. "$PSScriptRoot/common.ps1"

# Register a custom placeholder
Register-Placeholder -Name "TIMESTAMP" -ScriptBlock {
    param($Answers)
    return Get-Date -Format "yyyyMMdd_HHmmss"
}

# Now [[[TIMESTAMP]]] can be used anywhere in the workflow
```

#### Function Signature

```powershell
Register-Placeholder -Name <string> -ScriptBlock <scriptblock>
```

**Parameters:**

- **Name**: Placeholder name without `[[[  ]]]` brackets
- **ScriptBlock**: A scriptblock that generates the value, receives `$Answers` hashtable as parameter

#### Example 1: Simple Static Value

```powershell
# Register current date
Register-Placeholder -Name "DATE" -ScriptBlock {
    param($Answers)
    return Get-Date -Format "yyyy-MM-dd"
}
```

**Usage in steps.json:**

```json
{
  "type": "replace",
  "files": ["./README.md"],
  "target": "[[[CREATED_DATE]]]",
  "value": "[[[DATE]]]"
}
```

#### Example 2: Using Answer Data

```powershell
# Convert project name to uppercase
Register-Placeholder -Name "PROJECT_UPPER" -ScriptBlock {
    param($Answers)
    if ($Answers.ContainsKey("project_name")) {
        return $Answers["project_name"].ToUpper()
    }
    return ""
}
```

**Usage:**

```json
{
  "steps": [
    {
      "question_id": "project_name",
      "question": "Enter project name:",
      "input_type": "input"
    },
    {
      "actions": [
        {
          "type": "execute",
          "command": "Write-Host 'Creating [[[PROJECT_UPPER]]]'"
        }
      ]
    }
  ]
}
```

If user enters `my-project`, output: `Creating MY-PROJECT`

#### Example 3: Complex Processing (Real-World)

See [hooks/minecraftversion.ps1](d:\AddonDevelopment\addondev\hooks\minecraftversion.ps1) for a real implementation:

```powershell
# In hooks/minecraftversion.ps1
. "$PSScriptRoot/common.ps1"

# Extract major version from Minecraft version string
Register-Placeholder -Name "MC_VERSION_MAJOR" -ScriptBlock {
    param($Answers)
    if ($Answers.ContainsKey("mc_version")) {
        $version = $Answers["mc_version"]
        if ($version -match '^(\d+)\.') {
            return $Matches[1]
        }
    }
    return "0"
}

# Extract minor version
Register-Placeholder -Name "MC_VERSION_MINOR" -ScriptBlock {
    param($Answers)
    if ($Answers.ContainsKey("mc_version")) {
        $version = $Answers["mc_version"]
        if ($version -match '^\d+\.(\d+)') {
            return $Matches[1]
        }
    }
    return "0"
}

# Extract patch version
Register-Placeholder -Name "MC_VERSION_PATCH" -ScriptBlock {
    param($Answers)
    if ($Answers.ContainsKey("mc_version")) {
        $version = $Answers["mc_version"]
        if ($version -match '^\d+\.\d+\.(\d+)') {
            return $Matches[1]
        }
    }
    return "0"
}
```

**Usage:**

```json
{
  "steps": [
    {
      "question_id": "mc_version",
      "question": "Select Minecraft version:",
      "input_type": "minecraftversion"
    },
    {
      "actions": [
        {
          "type": "replace",
          "files": ["./config.json"],
          "target": "\"major\": 0",
          "value": "\"major\": [[[MC_VERSION_MAJOR]]]"
        }
      ]
    }
  ]
}
```

If user selects version `1.20.41-beta.1`:

- `[[[MC_VERSION_MAJOR]]]` → `1`
- `[[[MC_VERSION_MINOR]]]` → `20`
- `[[[MC_VERSION_PATCH]]]` → `41`

#### Example 4: Multiple Random Values

```powershell
# Generate unique random ID
Register-Placeholder -Name "RANDOM_ID" -ScriptBlock {
    param($Answers)
    return Get-Random -Minimum 10000 -Maximum 99999
}
```

**Note**: Unlike `[[[UUIDv4]]]`, this generates a NEW value each time `Invoke-Replacement` is called, but returns the SAME value for all occurrences within a single call.

#### When to Register Placeholders

**Best Practice**: Register placeholders at the top of your hook file, before defining hook functions.

```powershell
# Good: Register at the beginning
. "$PSScriptRoot/common.ps1"

Register-Placeholder -Name "MY_PLACEHOLDER" -ScriptBlock { ... }

function Get-UserInput { ... }
```

**Input Type Hooks**: Register before `Get-UserInput`, placeholders become available for all subsequent steps.

**Action Type Hooks**: Register before `Invoke-*Action`, placeholders become available immediately.

---

### Method 2: Direct Implementation (Legacy)

Modify the `Invoke-Replacement` function in `hooks/common.ps1`.

**⚠️ Not Recommended**: This method requires modifying core files and makes maintenance difficult.

**Use Dynamic Registration instead** unless you need:

- Built-in placeholders that should always be available
- Performance-critical operations
- Core system features

#### Current Implementation

```powershell
function Invoke-Replacement {
    param(
        [string]$Text,
        [hashtable]$Answers
    )

    $result = $Text

    # 1. Replace [[[ANS:question_id]]]
    foreach ($key in $Answers.Keys) {
        $placeholder = "[[[ANS:$key]]]"
        $result = $result -replace [regex]::Escape($placeholder), [regex]::Escape($Answers[$key])
    }

    # 2. Custom placeholders (registered dynamically)
    foreach ($placeholderName in $script:CustomPlaceholders.Keys) {
        $placeholder = "[[[${placeholderName}]]]"
        if ($result.Contains($placeholder)) {
            try {
                $value = & $script:CustomPlaceholders[$placeholderName] $Answers
                $result = $result.Replace($placeholder, $value)
            }
            catch {
                Write-Host "  [Warning] Failed to process custom placeholder [[[${placeholderName}]]]: $_" -ForegroundColor Yellow
            }
        }
    }

    # 3. Replace [[[UUIDv4]]]
    while ($result.Contains("[[[UUIDv4]]]")) {
        $newUUID = [guid]::NewGuid().ToString()
        $index = $result.IndexOf("[[[UUIDv4]]]")
        $result = $result.Substring(0, $index) + $newUUID + $result.Substring($index + "[[[UUIDv4]]]".Length)
    }

    # 4. Expand environment variables
    $result = [Environment]::ExpandEnvironmentVariables($result)

    # 5. Unescape \[[[ to [[[
    $result = $result -replace '\\(\[\[\[)', '$1'

    return $result
}
```

#### Example: Adding [[[DATE]]] Placeholder (Legacy)

**Requirement**: Insert current date in `yyyy-MM-dd` format

**Implementation**:

1. Open `hooks/common.ps1`
2. Add this code before the unescape step:

```powershell
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

    # Replace [[[UUIDv4]]]
    while ($result.Contains("[[[UUIDv4]]]")) {
        $newUUID = [guid]::NewGuid().ToString()
        $index = $result.IndexOf("[[[UUIDv4]]]")
        $result = $result.Substring(0, $index) + $newUUID + $result.Substring($index + "[[[UUIDv4]]]".Length)
    }

    # NEW: Replace [[[DATE]]] with current date
    if ($result.Contains("[[[DATE]]]")) {
        $currentDate = Get-Date -Format "yyyy-MM-dd"
        $result = $result -replace [regex]::Escape("[[[DATE]]]"), $currentDate
    }

    # Unescape \[[[ to [[[
    $result = $result -replace '\\(\[\[\[)', '$1'

    return $result
}
```

**Usage in steps.json:**

```json
{
  "type": "replace",
  "files": ["./README.md"],
  "target": "[[[CREATION_DATE]]]",
  "value": "[[[DATE]]]"
}
```

**Result:**

```
Project created on: 2026-02-14
```

**Note**: These examples show the legacy method. Use Dynamic Registration instead:

```powershell
# In any hook file
Register-Placeholder -Name "DATE" -ScriptBlock {
    param($Answers)
    return Get-Date -Format "yyyy-MM-dd"
}

Register-Placeholder -Name "DATETIME" -ScriptBlock {
    param($Answers)
    return Get-Date -Format "yyyy-MM-dd HH:mm:ss"
}

Register-Placeholder -Name "USER" -ScriptBlock {
    param($Answers)
    return $env:USERNAME
}
```

**Comparison:**

| Aspect          | Dynamic Registration | Legacy Method           |
| --------------- | -------------------- | ----------------------- |
| Code Location   | Any hook file        | `hooks/common.ps1` only |
| Modifies Core   | ❌ No                | ✅ Yes                  |
| Maintainability | ✅ High              | ❌ Low                  |
| Reusability     | ✅ High              | ⚠️ Medium               |
| Recommended     | ✅ Yes               | ❌ No                   |

---

## Guidelines for Custom Placeholders

### 1. Naming Convention

- Use ALL CAPS for placeholder names: `[[[DATE]]]`, not `[[[date]]]`
- Use descriptive names: `[[[TIMESTAMP]]]` not `[[[TS]]]`
- Use colons for parameters: `[[[RANDOM:8]]]` (if implementing parameterized placeholders)
- Avoid conflicts with built-in placeholders: `ANS`, `UUIDv4`

### 2. When to Use Dynamic Registration

**✅ Use Dynamic Registration for:**

- Hook-specific placeholders (e.g., `MC_VERSION_MAJOR` in `minecraftversion.ps1`)
- Workflow-specific transformations
- Reusable utilities that depend on user answers
- Experimental or temporary placeholders

**⚠️ Use Legacy Method (modify `common.ps1`) only for:**

- Core built-in placeholders needed system-wide
- Performance-critical operations
- Features that should always be available

### 3. Error Handling

**Dynamic Registration** (automatic error handling):

```powershell
Register-Placeholder -Name "SAFE_NAME" -ScriptBlock {
    param($Answers)
    try {
        return $Answers["name"].ToUpper()
    } catch {
        return "DEFAULT"
    }
}
```

**Legacy Method** (manual error handling):

```powershell
if ($result.Contains("[[[DATE]]]")) {
    try {
        $currentDate = Get-Date -Format "yyyy-MM-dd"
        $result = $result -replace [regex]::Escape("[[[DATE]]]"), $currentDate
    } catch {
        Write-Host "Warning: Failed to process [[[DATE]]] placeholder" -ForegroundColor Yellow
    }
}
```

### 4. Scope and Lifetime

**Dynamic placeholders** are registered once and available for all subsequent `Invoke-Replacement` calls:

```powershell
# In hooks/myhook.ps1 - registered when hook is loaded
Register-Placeholder -Name "TIMESTAMP" -ScriptBlock { ... }

# Available in all subsequent steps
```

**Lifetime**: Until PowerShell session ends or `generator.ps1` completes.

### 5. Documentation

When adding custom placeholders:

1. **For Hook-Specific Placeholders**: Document in hook file comments
2. **For Reusable Placeholders**: Document in workflow's README or steps.json comments
3. **For Built-in Placeholders**: Update this skill file and main README.md
4. Always include usage examples

---

## Testing Placeholders

### Test Configuration

Create `test-placeholders.json`:

```json
{
  "steps": [
    {
      "question_id": "name",
      "question": "Enter name:",
      "input_type": "input",
      "actions": [
        {
          "type": "execute",
          "command": "Write-Host 'Name: [[[ANS:name]]]'"
        },
        {
          "type": "execute",
          "command": "Write-Host 'UUID: [[[UUIDv4]]]'"
        },
        {
          "type": "execute",
          "command": "Write-Host 'Escaped: \\[[[ANS:name]]]'"
        }
      ]
    }
  ]
}
```

Run:

```powershell
.\generator.ps1 -StepPath "test-placeholders.json"
```

### Testing Custom Placeholders

**Create a test hook** (`hooks/test-custom.ps1`):

```powershell
. "$PSScriptRoot/common.ps1"

Register-Placeholder -Name "TIMESTAMP" -ScriptBlock {
    param($Answers)
    return Get-Date -Format "yyyyMMdd_HHmmss"
}

Register-Placeholder -Name "UPPER_NAME" -ScriptBlock {
    param($Answers)
    if ($Answers.ContainsKey("name")) {
        return $Answers["name"].ToUpper()
    }
    return ""
}

function Get-UserInput {
    param([string]$Question, [hashtable]$Answers)
    # Just return empty - this is for testing placeholders
    return ""
}
```

**Test workflow** (`test-custom-placeholders.steps.json`):

```json
{
  "steps": [
    {
      "question_id": "name",
      "question": "Enter name:",
      "input_type": "input"
    },
    {
      "question_id": "test",
      "question": "Test custom placeholders:",
      "input_type": "test-custom",
      "actions": [
        {
          "type": "execute",
          "command": "Write-Host 'TIMESTAMP: [[[TIMESTAMP]]]'"
        },
        {
          "type": "execute",
          "command": "Write-Host 'UPPER_NAME: [[[UPPER_NAME]]]'"
        }
      ]
    }
  ]
}
```

### Manual Testing

Test replacement independently:

```powershell
# Load the function
. "./hooks/common.ps1"

# Register a test placeholder
Register-Placeholder -Name "TEST" -ScriptBlock {
    param($Answers)
    return "Custom Value: $($Answers['name'])"
}

# Create test answers
$answers = @{
    "name" = "TestProject"
    "version" = "1.0.0"
}

# Test replacement
$text = "Project [[[ANS:name]]] version [[[ANS:version]]] - [[[TEST]]] - ID: [[[UUIDv4]]]"
$result = Invoke-Replacement -Text $text -Answers $answers

Write-Host "Original: $text"
Write-Host "Result: $result"
# Expected: Project TestProject version 1.0.0 - Custom Value: TestProject - ID: <uuid>
```

---

## Common Mistakes

### 1. Typo in Placeholder Name

❌ **Wrong:**

```json
{
  "command": "echo [[[ANS:projet_name]]]" // Typo: "projet" instead of "project"
}
```

**Result**: Placeholder not replaced, literal text `[[[ANS:projet_name]]]` appears.

**Solution**: Double-check `question_id` matches exactly.

### 2. Missing question_id

❌ **Wrong:**

```json
{
  "question": "Enter name:",
  "actions": [{ "type": "execute", "command": "echo [[[ANS:name]]]" }]
}
```

**Result**: No answer stored, placeholder not replaced.

**Solution**: Add `"question_id": "name"`.

### 3. Using Placeholder Before It's Defined

❌ **Wrong:**

```json
{
  "steps": [
    {
      "actions": [{ "type": "execute", "command": "echo [[[ANS:name]]]" }]
    },
    {
      "question_id": "name",
      "question": "Enter name:"
    }
  ]
}
```

**Solution**: Ask the question before using its answer.

### 4. Incorrect Escaping

❌ **Wrong:**

```json
{
  "value": "\[[[ANS:name]]]" // Single backslash in JSON
}
```

**Result**: After JSON parsing: `[ANS:name]]]` (malformed)

✅ **Correct:**

```json
{
  "value": "\\[[[ANS:name]]]" // Double backslash in JSON
}
```

---

## Best Practices

### General

1. ✅ Use descriptive question_ids that match placeholder intent
2. ✅ Test placeholders with simple examples first
3. ✅ Document custom placeholders appropriately (hook file, README, or skill file)
4. ✅ Use escaping for literal placeholder text in documentation
5. ✅ Handle errors gracefully in custom placeholder implementations
6. ✅ Test all placeholder combinations in your workflows

### For Dynamic Registration

7. ✅ Register placeholders at the top of hook files
8. ✅ Use meaningful names that describe the value transformation
9. ✅ Check if answer keys exist before accessing them
10. ✅ Provide default values when data is missing
11. ✅ Keep scriptblocks simple and focused on one transformation
12. ✅ Use `Write-Verbose` for debugging placeholder registration

### Example: Good vs Bad

**❌ Bad:**

```powershell
# Vague name, no error handling
Register-Placeholder -Name "VER" -ScriptBlock {
    param($Answers)
    return $Answers["version"].Split(".")[0]
}
```

**✅ Good:**

```powershell
# Clear name, error handling, default value
Register-Placeholder -Name "VERSION_MAJOR" -ScriptBlock {
    param($Answers)
    if ($Answers.ContainsKey("version") -and $Answers["version"] -match '^(\d+)') {
        return $Matches[1]
    }
    return "0"
}
```
