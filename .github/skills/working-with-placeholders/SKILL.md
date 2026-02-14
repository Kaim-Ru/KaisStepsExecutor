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

To add new placeholder types, modify the `Invoke-Replacement` function in `hooks/common.ps1`.

### Current Implementation

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

    # 2. Replace [[[UUIDv4]]]
    while ($result.Contains("[[[UUIDv4]]]")) {
        $newUUID = [guid]::NewGuid().ToString()
        $index = $result.IndexOf("[[[UUIDv4]]]")
        $result = $result.Substring(0, $index) + $newUUID + $result.Substring($index + "[[[UUIDv4]]]".Length)
    }

    # 3. Unescape \[[[ to [[[
    $result = $result -replace '\\(\[\[\[)', '$1'

    return $result
}
```

### Example: Adding [[[DATE]]] Placeholder

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

### Example: Adding [[[DATETIME]]] Placeholder

**Requirement**: Insert current datetime with timestamp

```powershell
# Replace [[[DATETIME]]]
if ($result.Contains("[[[DATETIME]]]")) {
    $currentDateTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $result = $result -replace [regex]::Escape("[[[DATETIME]]]"), $currentDateTime
}
```

### Example: Adding [[[USER]]] Placeholder

**Requirement**: Insert current Windows username

```powershell
# Replace [[[USER]]]
if ($result.Contains("[[[USER]]]")) {
    $currentUser = $env:USERNAME
    $result = $result -replace [regex]::Escape("[[[USER]]]"), $currentUser
}
```

### Example: Adding [[[RANDOM:N]]] Placeholder

**Requirement**: Generate N random digits

```powershell
# Replace [[[RANDOM:N]]] with N random digits
while ($result -match '\[\[\[RANDOM:(\d+)\]\]\]') {
    $length = [int]$Matches[1]
    $randomNumber = ""
    for ($i = 0; $i -lt $length; $i++) {
        $randomNumber += Get-Random -Minimum 0 -Maximum 10
    }
    $result = $result -replace [regex]::Escape("[[[RANDOM:$length]]]"), $randomNumber, 1
}
```

**Usage:**

```json
{
  "type": "replace",
  "files": ["./config.txt"],
  "target": "[[[ID]]]",
  "value": "[[[RANDOM:8]]]"
}
```

**Result:** `12345678` (8 random digits)

---

## Guidelines for Custom Placeholders

### 1. Naming Convention

- Use ALL CAPS for placeholder names: `[[[DATE]]]`, not `[[[date]]]`
- Use descriptive names: `[[[TIMESTAMP]]]` not `[[[TS]]]`
- Use colons for parameters: `[[[RANDOM:8]]]`

### 2. Processing Order

Add placeholders in this order within `Invoke-Replacement`:

1. **Context-dependent** (require $Answers): `[[[ANS:...]]]`
2. **Context-independent** (no dependencies): `[[[DATE]]]`, `[[[USER]]]`
3. **Dynamic/random**: `[[[UUIDv4]]]`, `[[[RANDOM:N]]]`
4. **Escaping**: Always last

### 3. Error Handling

```powershell
# Good: Handle potential errors
if ($result.Contains("[[[DATE]]]")) {
    try {
        $currentDate = Get-Date -Format "yyyy-MM-dd"
        $result = $result -replace [regex]::Escape("[[[DATE]]]"), $currentDate
    } catch {
        Write-Host "Warning: Failed to process [[[DATE]]] placeholder" -ForegroundColor Yellow
    }
}
```

### 4. Performance

For placeholders that appear multiple times:

```powershell
# Efficient: Replace all at once
if ($result.Contains("[[[DATE]]]")) {
    $currentDate = Get-Date -Format "yyyy-MM-dd"
    $result = $result -replace [regex]::Escape("[[[DATE]]]"), $currentDate
}

# Less efficient: Loop for unique values
while ($result.Contains("[[[UUIDv4]]]")) {
    $newUUID = [guid]::NewGuid().ToString()
    $index = $result.IndexOf("[[[UUIDv4]]]")
    $result = $result.Substring(0, $index) + $newUUID + $result.Substring($index + 13)
}
```

### 5. Documentation

When adding placeholders:

1. Update `hooks/common.ps1` with implementation
2. Document in `README.md` under "Placeholders" section
3. Document in this skill file
4. Add usage examples

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
          "command": "Write-Host 'Date: [[[DATE]]]'"
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

### Manual Testing

Test replacement independently:

```powershell
# Load the function
. "./hooks/common.ps1"

# Create test answers
$answers = @{
    "name" = "TestProject"
    "version" = "1.0.0"
}

# Test replacement
$text = "Project [[[ANS:name]]] version [[[ANS:version]]] ID: [[[UUIDv4]]]"
$result = Invoke-Replacement -Text $text -Answers $answers

Write-Host "Original: $text"
Write-Host "Result: $result"
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

1. ✅ Use descriptive question_ids that match placeholder intent
2. ✅ Test placeholders with simple examples first
3. ✅ Document custom placeholders in README.md
4. ✅ Use escaping for literal placeholder text in documentation
5. ✅ Consider placeholder processing order when adding custom ones
6. ✅ Handle errors gracefully in custom placeholder implementations
7. ✅ Use `[regex]::Escape()` when replacing with user input
8. ✅ Test all placeholder combinations in your workflows
