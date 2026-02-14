---
name: debugging-and-testing
description: Test workflows, debug issues, and troubleshoot common problems in the automation system
---

# Skill: Debugging and Testing

## Overview

This skill teaches AI agents how to test workflows, debug issues, and troubleshoot common problems in the automation system.

---

## Testing Workflows

### Creating Test Configurations

**Minimal Test**:

```json
{
  "steps": [
    {
      "question_id": "test",
      "question": "Enter test value:",
      "actions": [
        {
          "type": "execute",
          "command": "Write-Host 'Value: [[[ANS:test]]]'"
        }
      ]
    }
  ]
}
```

Save as `test-simple.json` and run:

```powershell
.\generator.ps1 -StepPath "test-simple.json"
```

### Test Configuration Patterns

**Test Input Types**:

```json
{
  "steps": [
    {
      "question_id": "input_test",
      "question": "Text input:",
      "input_type": "input"
    },
    {
      "question_id": "select_test",
      "question": "Select one:",
      "input_type": "select",
      "options": ["Option A", "Option B", "Option C"]
    },
    {
      "question_id": "multi_test",
      "question": "Select multiple:",
      "input_type": "multiselect",
      "options": ["Feature 1", "Feature 2", "Feature 3"]
    },
    {
      "actions": [
        {
          "type": "execute",
          "command": "Write-Host 'Input: [[[ANS:input_test]]]'"
        },
        {
          "type": "execute",
          "command": "Write-Host 'Select: [[[ANS:select_test]]]'"
        },
        {
          "type": "execute",
          "command": "Write-Host 'Multi: [[[ANS:multi_test]]]'"
        }
      ]
    }
  ]
}
```

**Test Actions**:

```json
{
  "steps": [
    {
      "question_id": "name",
      "question": "Project name:",
      "actions": [
        {
          "type": "mkdir",
          "path": "./test_[[[ANS:name]]]"
        },
        {
          "type": "writefile",
          "path": "./test_[[[ANS:name]]]/README.md",
          "content": "# [[[ANS:name]]]\n\nTest project"
        },
        {
          "type": "copy",
          "source": "./test_[[[ANS:name]]]",
          "destination": "./test_[[[ANS:name]]]-backup/"
        },
        {
          "type": "delete",
          "path": "./test_[[[ANS:name]]]-backup",
          "confirm": false
        }
      ]
    }
  ]
}
```

**Test Conditions**:

```json
{
  "steps": [
    {
      "question_id": "enable",
      "question": "Enable feature?",
      "input_type": "select",
      "options": ["Yes", "No"]
    },
    {
      "actions": [
        {
          "type": "execute",
          "command": "Write-Host 'Feature enabled!' -ForegroundColor Green",
          "conditions": [{ "question_id": "enable", "ans": "Yes" }]
        },
        {
          "type": "execute",
          "command": "Write-Host 'Feature disabled!' -ForegroundColor Red",
          "conditions": [{ "question_id": "enable", "ans": "No" }]
        }
      ]
    }
  ]
}
```

**Test Placeholders**:

```json
{
  "steps": [
    {
      "question_id": "name",
      "question": "Name:",
      "actions": [
        {
          "type": "execute",
          "command": "Write-Host 'ANS: [[[ANS:name]]]'"
        },
        {
          "type": "execute",
          "command": "Write-Host 'UUID1: [[[UUIDv4]]]'"
        },
        {
          "type": "execute",
          "command": "Write-Host 'UUID2: [[[UUIDv4]]]'"
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

---

## Debugging Techniques

### 1. Add Debug Output

Add `Write-Host` statements in hooks:

```powershell
function Invoke-CustomAction {
    param([object]$Action, [hashtable]$Answers)

    # DEBUG: Show what we received
    Write-Host "DEBUG: Action = $($Action | ConvertTo-Json -Depth 3)" -ForegroundColor Magenta
    Write-Host "DEBUG: Answers = $($Answers | ConvertTo-Json)" -ForegroundColor Magenta

    # Process...
    $value = Invoke-Replacement -Text $Action.value -Answers $Answers
    Write-Host "DEBUG: Processed value = $value" -ForegroundColor Magenta

    # Continue...
}
```

### 2. Test Placeholder Replacement

Test `Invoke-Replacement` independently:

```powershell
# Load the function
. "./hooks/common.ps1"

# Create test data
$answers = @{
    "project_name" = "MyProject"
    "author" = "John Doe"
    "version" = "1.0.0"
}

# Test replacement
$text = "Project [[[ANS:project_name]]] by [[[ANS:author]]] v[[[ANS:version]]]"
$result = Invoke-Replacement -Text $text -Answers $answers

Write-Host "Input:  $text"
Write-Host "Output: $result"

# Test UUIDs
$text2 = "ID1: [[[UUIDv4]]], ID2: [[[UUIDv4]]]"
$result2 = Invoke-Replacement -Text $text2 -Answers $answers
Write-Host "UUIDs: $result2"

# Test escaping
$text3 = "Escaped: \\[[[ANS:project_name]]]"
$result3 = Invoke-Replacement -Text $text3 -Answers $answers
Write-Host "Escaped: $result3"
```

### 3. Validate JSON Before Running

```powershell
# Test JSON syntax
try {
    $config = Get-Content -Path "steps.json" -Raw | ConvertFrom-Json
    Write-Host "✓ JSON is valid" -ForegroundColor Green

    # Check steps count
    Write-Host "Steps: $($config.steps.Count)" -ForegroundColor Cyan

    # List question IDs
    foreach ($step in $config.steps) {
        if ($step.question_id) {
            Write-Host "  - $($step.question_id)" -ForegroundColor Gray
        }
    }
} catch {
    Write-Host "✗ JSON is invalid: $_" -ForegroundColor Red
}
```

### 4. Test Path Resolution

```powershell
# Test path handling
$testPaths = @(
    "./relative/path"
    ".\relative\path"
    "C:\absolute\path"
    "D:/absolute/path"
    "./path with spaces/file.txt"
)

foreach ($path in $testPaths) {
    Write-Host "Input:    $path" -ForegroundColor Cyan

    if ([System.IO.Path]::IsPathRooted($path)) {
        Write-Host "Type:     Absolute" -ForegroundColor Green
        Write-Host "Resolved: $path" -ForegroundColor Green
    } else {
        Write-Host "Type:     Relative" -ForegroundColor Yellow
        $resolved = Join-Path (Get-Location) $path
        Write-Host "Resolved: $resolved" -ForegroundColor Yellow
    }
    Write-Host ""
}
```

### 5. Check Hook Loading

Add debug output to `generator.ps1` (temporary):

```powershell
# Before: . $hookPath
Write-Host "DEBUG: Loading hook: $hookPath" -ForegroundColor Magenta

if (Test-Path $hookPath) {
    Write-Host "DEBUG: Hook file exists" -ForegroundColor Magenta
    . $hookPath
    Write-Host "DEBUG: Hook loaded successfully" -ForegroundColor Magenta
} else {
    Write-Host "DEBUG: Hook file NOT found" -ForegroundColor Red
}
```

---

## Common Issues and Solutions

### Issue 1: Hook Not Found

**Error**:

```
[Warning] Hook not found for action type 'custom': D:\...\hooks\custom.ps1
Skipping this action.
```

**Debugging Steps**:

1. Check file exists:

   ```powershell
   Test-Path "./hooks/custom.ps1"
   ```

2. Check filename exactly matches action type:

   ```json
   { "type": "custom" }  ← Must match → hooks/custom.ps1
   ```

3. Check case sensitivity (important on Linux/Mac)

4. Verify file extension is `.ps1`

**Solution**:

- Create the hook file with correct name
- Ensure filename is lowercase
- Match the action type exactly

---

### Issue 2: Function Not Defined

**Error**:

```
Invoke-CustomAction : The term 'Invoke-CustomAction' is not recognized...
```

**Debugging Steps**:

1. Check function name in hook file:

   ```powershell
   # File: hooks/custom.ps1
   function Invoke-CustomAction {  # Must be exactly this name
   ```

2. Verify naming pattern:
   - Input type: `Get-UserInput`
   - Action type: `Invoke-{Type}Action` (PascalCase)

3. Check for typos:
   ```powershell
   # Wrong: function Invoke-Custom
   # Right: function Invoke-CustomAction
   ```

**Solution**:

- Fix function name to match pattern
- Ensure action type in JSON is lowercase: `"type": "custom"`
- Function name must be in PascalCase: `Invoke-CustomAction`

---

### Issue 3: Placeholder Not Replaced

**Error**:
File contains literal text: `[[[ANS:project_name]]]`

**Debugging Steps**:

1. Check `question_id` exists and matches:

   ```json
   {
     "question_id": "project_name",  ← This
     "question": "...",
     "actions": [
       { "command": "echo [[[ANS:project_name]]]" }  ← Must match this
     ]
   }
   ```

2. Verify question was asked before placeholder used:

   ```json
   {
     "steps": [
       { "question_id": "name", ... },  ← Ask first
       { "actions": [{ "command": "echo [[[ANS:name]]]" }] }  ← Use later
     ]
   }
   ```

3. Check if `Invoke-Replacement` is being called:

   ```powershell
   # In hook file, must have:
   $command = Invoke-Replacement -Text $Action.command -Answers $Answers
   ```

4. Test replacement manually:
   ```powershell
   . "./hooks/common.ps1"
   $answers = @{ "project_name" = "TestProject" }
   $result = Invoke-Replacement -Text "[[[ANS:project_name]]]" -Answers $answers
   Write-Host $result  # Should output: TestProject
   ```

**Solution**:

- Fix typo in `question_id` or placeholder
- Ensure question is asked before using answer
- Verify `Invoke-Replacement` is called in hook

---

### Issue 4: Condition Not Working

**Error**:
Action skipped unexpectedly (or executed when it shouldn't)

**Debugging Steps**:

1. Add debug output to see condition values:

   ```powershell
   # In generator.ps1 Test-Conditions function:
   Write-Host "DEBUG: Checking condition" -ForegroundColor Magenta
   Write-Host "DEBUG: question_id = $questionId" -ForegroundColor Magenta
   Write-Host "DEBUG: Expected = $expectedAns" -ForegroundColor Magenta
   Write-Host "DEBUG: Actual = $($Answers[$questionId])" -ForegroundColor Magenta
   ```

2. Check exact match (case-sensitive):

   ```json
   {
     "conditions": [
       { "question_id": "framework", "ans": "React" }  ← Must match exactly
     ]
   }
   ```

3. For multiselect, use regex:

   ```json
   {
     "question_id": "features",
     "input_type": "multiselect",
     "options": ["TypeScript", "ESLint"],
     "actions": [
       {
         "conditions": [
           { "question_id": "features", "ans": { "regex": "TypeScript" } }
         ]
       }
     ]
   }
   ```

4. Test regex patterns:
   ```powershell
   $answer = "TypeScript, ESLint"
   if ($answer -match "TypeScript") {
       Write-Host "Match!" -ForegroundColor Green
   }
   ```

**Solution**:

- Check for typos in condition values
- Use exact match for select, regex for multiselect
- Verify question was answered before condition checked

---

### Issue 5: Path Not Found

**Error**:

```
✗ Source not found: template/config
```

**Debugging Steps**:

1. Check current directory:

   ```powershell
   Get-Location
   ```

2. Check if path exists:

   ```powershell
   Test-Path "./template/config"
   Test-Path "D:/AddonDevelopment/psteset12/template/config"
   ```

3. List directory contents:

   ```powershell
   Get-ChildItem "./template"
   ```

4. Check path separators:

   ```powershell
   # Both should work on Windows:
   "./template/config"
   ".\template\config"
   ```

5. Test path resolution:
   ```powershell
   $relative = "./template/config"
   $absolute = Join-Path (Get-Location) $relative
   Write-Host "Relative: $relative"
   Write-Host "Absolute: $absolute"
   Test-Path $absolute
   ```

**Solution**:

- Use correct relative or absolute path
- Verify file/directory exists
- Check for typos in path
- Ensure current directory is correct

---

### Issue 6: Encoding Issues

**Error**:
Special characters appear as: `ãã` or `???`

**Debugging Steps**:

1. Check file encoding:

   ```powershell
   # In hook, ensure UTF-8:
   Get-Content -Path $file -Raw -Encoding UTF8
   ```

2. Verify write encoding:
   ```powershell
   Set-Content -Path $file -Value $content -Encoding UTF8 -NoNewline
   ```

**Solution**:

- Always use `-Encoding UTF8` for Get-Content and Set-Content
- Ensure source files are UTF-8 encoded
- Use UTF-8 without BOM for best compatibility

---

### Issue 7: Wildcard Pattern Not Working

**Error**:

```
⚠ No files found to replace
```

**Debugging Steps**:

1. Test pattern manually:

   ```powershell
   Get-ChildItem -Path "./template" -Filter "*.txt" -Recurse
   ```

2. Check pattern syntax:

   ```json
   {
     "files": ["./template/**/*.txt"] // Correct
     // Not: "./template/**.txt"
   }
   ```

3. Test with simpler pattern:

   ```json
   {
     "files": ["./template/*.txt"] // Try without **
   }
   ```

4. Check exclude patterns:
   ```json
   {
     "files": {
       "include": ["./template/**/*.txt"],
       "exclude": ["**/node_modules/**"] // Might be excluding too much
     }
   }
   ```

**Solution**:

- Use correct wildcard syntax
- Test with simpler patterns first
- Check exclude patterns aren't too broad
- Verify files actually exist with Get-ChildItem

---

## Testing Checklist

When testing a new hook or workflow:

- [ ] **JSON Syntax**: Validate with `ConvertFrom-Json`
- [ ] **Hook File Exists**: Check with `Test-Path`
- [ ] **Function Name**: Matches pattern exactly
- [ ] **Placeholder Processing**: Test with manual data
- [ ] **Path Handling**: Test relative and absolute paths
- [ ] **Encoding**: Verify UTF-8 for all file operations
- [ ] **Error Handling**: Test with invalid inputs
- [ ] **Edge Cases**: Empty inputs, special characters, long values
- [ ] **Conditions**: Test all branches
- [ ] **Cleanup**: Remove test files/directories

---

## Automated Testing Script

Create `test-all.ps1`:

```powershell
# Test script for validating hooks and configurations

Write-Host "Starting tests..." -ForegroundColor Cyan
Write-Host ""

$pass = 0
$fail = 0

# Test 1: Validate JSON syntax
Write-Host "Test 1: JSON syntax..." -NoNewline
try {
    $config = Get-Content -Path "steps.json" -Raw | ConvertFrom-Json
    Write-Host " PASS" -ForegroundColor Green
    $pass++
} catch {
    Write-Host " FAIL: $_" -ForegroundColor Red
    $fail++
}

# Test 2: Check all hooks exist
Write-Host "Test 2: Hook files exist..." -NoNewline
$hookTypes = @("input", "select", "multiselect", "execute", "replace", "copy", "symlink", "mkdir")
$allExist = $true
foreach ($type in $hookTypes) {
    if (-not (Test-Path "./hooks/$type.ps1")) {
        Write-Host " FAIL: Missing hooks/$type.ps1" -ForegroundColor Red
        $allExist = $false
        $fail++
    }
}
if ($allExist) {
    Write-Host " PASS" -ForegroundColor Green
    $pass++
}

# Test 3: Test placeholder replacement
Write-Host "Test 3: Placeholder replacement..." -NoNewline
try {
    . "./hooks/common.ps1"
    $answers = @{ "test" = "VALUE" }
    $result = Invoke-Replacement -Text "[[[ANS:test]]]" -Answers $answers
    if ($result -eq "VALUE") {
        Write-Host " PASS" -ForegroundColor Green
        $pass++
    } else {
        Write-Host " FAIL: Expected 'VALUE', got '$result'" -ForegroundColor Red
        $fail++
    }
} catch {
    Write-Host " FAIL: $_" -ForegroundColor Red
    $fail++
}

# Test 4: Test UUID generation
Write-Host "Test 4: UUID generation..." -NoNewline
try {
    . "./hooks/common.ps1"
    $result = Invoke-Replacement -Text "[[[UUIDv4]]]" -Answers @{}
    if ($result -match '^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$') {
        Write-Host " PASS" -ForegroundColor Green
        $pass++
    } else {
        Write-Host " FAIL: Invalid UUID format" -ForegroundColor Red
        $fail++
    }
} catch {
    Write-Host " FAIL: $_" -ForegroundColor Red
    $fail++
}

# Summary
Write-Host ""
Write-Host "==================" -ForegroundColor Cyan
Write-Host "Tests passed: $pass" -ForegroundColor Green
Write-Host "Tests failed: $fail" -ForegroundColor Red
Write-Host "==================" -ForegroundColor Cyan

if ($fail -eq 0) {
    Write-Host "All tests passed!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "Some tests failed!" -ForegroundColor Red
    exit 1
}
```

Run:

```powershell
.\test-all.ps1
```

---

## Performance Profiling

### Measure Execution Time

```powershell
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

# Your operation here
.\generator.ps1 -StepPath "steps.json"

$stopwatch.Stop()
Write-Host "Execution time: $($stopwatch.Elapsed.TotalSeconds) seconds" -ForegroundColor Cyan
```

### Profile Individual Operations

```powershell
$start = Get-Date
# Operation
$end = Get-Date
$duration = $end - $start
Write-Host "Duration: $($duration.TotalMilliseconds) ms" -ForegroundColor Gray
```

---

## Best Practices Summary

### Testing

1. ✅ Start with minimal test configurations
2. ✅ Test one feature at a time
3. ✅ Use descriptive test file names
4. ✅ Test edge cases and error conditions
5. ✅ Clean up test files after testing

### Debugging

1. ✅ Add debug output with `Write-Host`
2. ✅ Test components independently
3. ✅ Validate JSON syntax before running
4. ✅ Check file paths with `Test-Path`
5. ✅ Use try-catch to catch errors early

### Troubleshooting

1. ✅ Read error messages carefully
2. ✅ Check obvious issues first (typos, paths)
3. ✅ Test with simpler configurations
4. ✅ Add logging to understand execution flow
5. ✅ Compare with working examples
