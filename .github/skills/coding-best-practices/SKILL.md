---
name: coding-best-practices
description: Follow coding standards, conventions, and best practices for developing and maintaining this PowerShell-based automation system
---

# Skill: Coding Best Practices

## Overview

This skill teaches AI agents the coding standards, conventions, and best practices for developing and maintaining this PowerShell-based automation system.

---

## Naming Conventions

### File Names

**Hook Files**:

- Lowercase, no spaces: `input.ps1`, `select.ps1`, `download.ps1`
- Match the type name exactly (case-sensitive on some systems)
- Use descriptive names: `multiselect.ps1` not `multi.ps1`

**Configuration Files**:

- Lowercase with hyphens: `steps.json`, `test-custom-hooks.json`
- Use `.json` extension for configuration

### Function Names

**Input Type Hooks**:

```powershell
function Get-UserInput {  # Always this exact name
    param([string]$Question, [hashtable]$Answers)
}
```

**Action Type Hooks**:

```powershell
# Pattern: Invoke-{ActionType}Action
function Invoke-ExecuteAction { }
function Invoke-ReplaceAction { }
function Invoke-DownloadAction { }
```

**Mapping**:
| JSON Type | Function Name |
|--------------|----------------------------|
| `execute` | `Invoke-ExecuteAction` |
| `replace` | `Invoke-ReplaceAction` |
| `download` | `Invoke-DownloadAction` |
| `gitinit` | `Invoke-GitinitAction` |

**Rules**:

- ActionType converted to PascalCase
- Must match pattern exactly
- Case-sensitive

### Variable Names

**PowerShell Convention (PascalCase)**:

```powershell
$FilePath
$SourceDirectory
$UserInput
$ProcessedQuestion
$NewUUID
```

**Parameter Names**:

```powershell
param(
    [string]$Question,      # PascalCase
    [array]$Options,
    [hashtable]$Answers,
    [object]$Action
)
```

**Local Variables**:

```powershell
$result = "something"
$processedText = Invoke-Replacement -Text $text -Answers $Answers
$destinationPath = Join-Path $base $relative
```

---

## Code Structure

### Hook File Template

```powershell
# Action/Input type: {type} ({description})
#
# Additional documentation if needed
#
# Example usage in steps.json:
# {
#   "type": "{type}",
#   "property": "value"
# }

. "$PSScriptRoot/common.ps1"

function Invoke-{Type}Action {  # or Get-UserInput
    param(
        [object]$Action,        # or [string]$Question
        [hashtable]$Answers
    )

    Write-Host "  [{Type}] Starting..." -ForegroundColor Cyan

    # 1. Process placeholders
    $property = Invoke-Replacement -Text $Action.property -Answers $Answers

    # 2. Validate inputs
    if (-not $property) {
        Write-Host "    ✗ Property is required" -ForegroundColor Red
        throw "Property is required"
    }

    # 3. Resolve paths (if applicable)
    if (-not [System.IO.Path]::IsPathRooted($path)) {
        $path = Join-Path (Get-Location) $path
    }

    # 4. Perform action with error handling
    try {
        # Your logic here

        Write-Host "    ✓ Success detail" -ForegroundColor Green
        Write-Host "  ✓ {Type} completed" -ForegroundColor Green
    } catch {
        Write-Host "    ✗ Error: $_" -ForegroundColor Red
        throw
    }
}
```

### Order of Operations

1. **Source common.ps1**
2. **Process placeholders** in all properties
3. **Validate inputs**
4. **Resolve paths** (absolute/relative)
5. **Create directories** if needed
6. **Perform main operation** in try-catch
7. **Provide feedback** with colored messages

---

## Output and Messaging

### Color Scheme

**Standard Colors**:

```powershell
Write-Host "  [Action] Starting..." -ForegroundColor Cyan      # Action headers
Write-Host "  > Command or detail" -ForegroundColor Gray       # Secondary info
Write-Host "    ✓ Success message" -ForegroundColor Green      # Success
Write-Host "    ✗ Error message" -ForegroundColor Red          # Errors
Write-Host "    ℹ Info message" -ForegroundColor Yellow        # Info/warnings
Write-Host "    ⚠ Warning message" -ForegroundColor Yellow     # Warnings
```

**Usage Examples**:

```powershell
# Action start
Write-Host "  [Copy] Copying file/folder..." -ForegroundColor Cyan

# Command being executed
Write-Host "  > npm install express" -ForegroundColor Gray

# Operation detail
Write-Host "    ✓ template/config.txt -> project/config.txt" -ForegroundColor Green

# Completion
Write-Host "  ✓ Copy completed" -ForegroundColor Green

# Error
Write-Host "    ✗ Source not found: $source" -ForegroundColor Red

# Warning/Info
Write-Host "    ℹ Already exists: $path" -ForegroundColor Yellow
```

### Symbol Usage

| Symbol | Meaning             | Usage                   |
| ------ | ------------------- | ----------------------- |
| `✓`    | Success, completion | Successful operations   |
| `✗`    | Error, failure      | Failed operations       |
| `ℹ`    | Information         | Already exists, skipped |
| `⚠`    | Warning             | Potential issues        |
| `>`    | Command/detail      | Commands being executed |

### Message Format

**Multi-line Action**:

```powershell
Write-Host "  [ActionType] Action description..." -ForegroundColor Cyan
Write-Host "  > Additional context" -ForegroundColor Gray
Write-Host "    ✓ Detail 1" -ForegroundColor Green
Write-Host "    ✓ Detail 2" -ForegroundColor Green
Write-Host "  ✓ Action completed" -ForegroundColor Green
```

**Single-line Action**:

```powershell
Write-Host "  [ActionType] Action description..." -ForegroundColor Cyan
Write-Host "  ✓ Action completed" -ForegroundColor Green
```

### Indentation

- Action headers: 2 spaces
- Details/suboperations: 4 spaces
- Commands: 2 spaces with `>`

```
  [Action] Starting...
  > Command being run
    ✓ Success detail
    ✓ Another detail
  ✓ Action completed
```

---

## Path Handling

### Always Support Both Path Types

```powershell
# Check if path is absolute
if (-not [System.IO.Path]::IsPathRooted($path)) {
    # Convert relative to absolute
    $path = Join-Path (Get-Location) $path
}
```

**Note**: `Get-Location` returns current working directory.

### Handle Both Path Separators

PowerShell handles both `/` and `\` on Windows:

```powershell
$path = "./template/config.txt"   # Works
$path = ".\template\config.txt"   # Also works
```

For cross-platform compatibility:

```powershell
$separator = [System.IO.Path]::DirectorySeparatorChar
$path = "template$separator" + "config.txt"
```

### Create Parent Directories

```powershell
$parentDir = Split-Path -Parent $filePath
if ($parentDir -and -not (Test-Path $parentDir)) {
    New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
}
```

**Always use** when creating files in non-existent directories.

### Trailing Slash Handling

For actions like `copy` and `symlink`:

```powershell
# Check if destination ends with slash
if ($Action.destination -match '[\\/]$') {
    # Treat as directory - copy INTO it
    $folderName = Split-Path -Leaf $source
    $destination = Join-Path $destination $folderName
}
```

---

## File Operations

### Reading Files

**Always use UTF-8 encoding**:

```powershell
$content = Get-Content -Path $filePath -Raw -Encoding UTF8
```

**Options**:

- `-Raw`: Returns entire file as single string (not array of lines)
- `-Encoding UTF8`: Ensures proper encoding

### Writing Files

```powershell
Set-Content -Path $filePath -Value $content -Encoding UTF8 -NoNewline
```

**Options**:

- `-Encoding UTF8`: Consistent encoding
- `-NoNewline`: Prevents extra newline at end

### File Existence Checks

```powershell
# Check if exists
if (Test-Path $path) {
    # File or directory exists
}

# Check if it's a file
if (Test-Path $path -PathType Leaf) {
    # It's a file
}

# Check if it's a directory
if (Test-Path $path -PathType Container) {
    # It's a directory
}
```

### Creating Directories

```powershell
New-Item -ItemType Directory -Path $path -Force | Out-Null
```

**Options**:

- `-Force`: Creates parent directories if needed
- `| Out-Null`: Suppresses output

### Copying Files

```powershell
Copy-Item -Path $source -Destination $destination -Recurse -Force
```

**Options**:

- `-Recurse`: Copy directories recursively
- `-Force`: Overwrite existing files

---

## Error Handling

### Use Try-Catch Blocks

```powershell
try {
    # Operations that might fail
    $content = Get-Content -Path $path -Raw -Encoding UTF8 -ErrorAction Stop

    # Success feedback
    Write-Host "    ✓ File read successfully" -ForegroundColor Green
    Write-Host "  ✓ Operation completed" -ForegroundColor Green
} catch {
    # Error feedback
    Write-Host "    ✗ Failed to read file: $_" -ForegroundColor Red
    throw  # Re-throw to stop execution
}
```

**Key Points**:

- Always use `-ErrorAction Stop` for commands in try block
- Provide specific error messages
- Re-throw with `throw` to stop execution

### Pre-Validation

Validate before attempting operations:

```powershell
# Validate required property
if (-not $Action.property) {
    Write-Host "    ✗ Property 'property' is required" -ForegroundColor Red
    throw "Property 'property' is required"
}

# Validate file exists
if (-not (Test-Path $source)) {
    Write-Host "    ✗ Source not found: $source" -ForegroundColor Red
    throw "Source not found: $source"
}

# Validate format
if ($url -notmatch '^https?://') {
    Write-Host "    ✗ Invalid URL format: $url" -ForegroundColor Red
    throw "Invalid URL format: $url"
}
```

### Helpful Error Messages

❌ **Bad**:

```powershell
catch {
    Write-Host "Error: $_" -ForegroundColor Red
    throw
}
```

✅ **Good**:

```powershell
catch {
    Write-Host "    ✗ Failed to download file: $_" -ForegroundColor Red
    Write-Host "    ℹ Check network connection and URL validity" -ForegroundColor Yellow
    Write-Host "    ℹ URL: $url" -ForegroundColor Yellow
    throw
}
```

### Handling Expected Conditions

```powershell
if (Test-Path $destination) {
    Write-Host "    ℹ File already exists: $destination" -ForegroundColor Yellow

    if ($Action.overwrite) {
        Write-Host "    ℹ Overwriting..." -ForegroundColor Yellow
        Remove-Item -Path $destination -Force
    } else {
        Write-Host "    ℹ Skipping (overwrite not enabled)" -ForegroundColor Yellow
        return
    }
}
```

---

## Placeholder Processing

### Always Use Invoke-Replacement

```powershell
# Process single property
$value = Invoke-Replacement -Text $Action.value -Answers $Answers

# Process multiple properties
$source = Invoke-Replacement -Text $Action.source -Answers $Answers
$destination = Invoke-Replacement -Text $Action.destination -Answers $Answers
$command = Invoke-Replacement -Text $Action.command -Answers $Answers
```

### Process Arrays

```powershell
$processedOptions = @()
foreach ($option in $Options) {
    $processedOptions += Invoke-Replacement -Text $option -Answers $Answers
}
```

### Escape Special Characters

When using processed values in regex:

```powershell
# Escape for regex use
$pattern = [regex]::Escape($processedValue)

# Replace with escaped value
$result = $text -replace $pattern, [regex]::Escape($replacement)
```

---

## Comments and Documentation

### File Header Comments

```powershell
# Action type: download (download file from URL)
#
# Downloads a file from the specified URL to the destination path.
# Supports both absolute and relative paths.
#
# Example usage in steps.json:
# {
#   "type": "download",
#   "url": "https://example.com/file.zip",
#   "destination": "./downloads/file.zip"
# }
```

### Inline Comments

```powershell
# Process placeholders in all properties
$url = Invoke-Replacement -Text $Action.url -Answers $Answers
$destination = Invoke-Replacement -Text $Action.destination -Answers $Answers

# Resolve destination path (support relative paths)
if (-not [System.IO.Path]::IsPathRooted($destination)) {
    $destination = Join-Path (Get-Location) $destination
}

# Create parent directory if it doesn't exist
$parentDir = Split-Path -Parent $destination
if ($parentDir -and -not (Test-Path $parentDir)) {
    New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
}
```

**Guidelines**:

- Comment WHY, not WHAT (code shows what)
- Explain non-obvious logic
- Document assumptions
- Note platform-specific behavior

---

## PowerShell Best Practices

### Use Proper Cmdlets

✅ **Good**:

```powershell
Get-ChildItem -Path $path -Filter "*.txt"
Test-Path $path
Join-Path $base $relative
```

❌ **Avoid**:

```powershell
ls $path        # Alias
dir $path       # Alias
$base + "\" + $relative  # Manual concatenation
```

### Parameter Splatting

For multiple parameters:

```powershell
$params = @{
    Path = $source
    Destination = $destination
    Recurse = $true
    Force = $true
}
Copy-Item @params
```

### Pipeline Usage

```powershell
# Good for filtering
Get-ChildItem -Path $path -Recurse |
    Where-Object { $_.Extension -eq '.txt' } |
    ForEach-Object { Process-File $_.FullName }
```

### Out-Null for Silent Operations

```powershell
New-Item -ItemType Directory -Path $path -Force | Out-Null
git init 2>&1 | Out-Null
```

---

## Performance Considerations

### Avoid Unnecessary File Operations

❌ **Inefficient**:

```powershell
# Reading same file multiple times
$content = Get-Content $file -Raw -Encoding UTF8
$content = $content -replace "A", "1"
Set-Content $file -Value $content -Encoding UTF8

$content = Get-Content $file -Raw -Encoding UTF8
$content = $content -replace "B", "2"
Set-Content $file -Value $content -Encoding UTF8
```

✅ **Efficient**:

```powershell
# Process all replacements at once
$content = Get-Content $file -Raw -Encoding UTF8
$content = $content -replace "A", "1"
$content = $content -replace "B", "2"
Set-Content $file -Value $content -Encoding UTF8
```

### Use -Filter Instead of -Include

```powershell
# Faster
Get-ChildItem -Path $path -Filter "*.txt"

# Slower
Get-ChildItem -Path $path -Include "*.txt"
```

### Regex Compilation

For repeated regex operations:

```powershell
$regex = [regex]::new($pattern, [System.Text.RegularExpressions.RegexOptions]::Compiled)
$result = $regex.Replace($text, $replacement)
```

---

## Security Considerations

### User Input Validation

```powershell
# Validate before using in commands
if ($name -match '[^a-zA-Z0-9_-]') {
    Write-Host "    ✗ Invalid characters in name" -ForegroundColor Red
    throw "Name contains invalid characters"
}
```

### Avoid Invoke-Expression with User Input

❌ **Dangerous**:

```powershell
$command = $Action.command  # User-controlled
Invoke-Expression $command  # Can execute arbitrary code
```

✅ **Safer**:

```powershell
# Process and validate
$command = Invoke-Replacement -Text $Action.command -Answers $Answers

# Or use specific cmdlets instead of Invoke-Expression
Start-Process -FilePath "cmd.exe" -ArgumentList "/c", $command
```

### File Permissions

```powershell
# Check write permissions before operations
try {
    [System.IO.File]::OpenWrite($path).Close()
} catch {
    Write-Host "    ✗ No write permission: $path" -ForegroundColor Red
    throw "No write permission: $path"
}
```

---

## Testing Best Practices

### Create Test Configurations

```json
{
  "steps": [
    {
      "question_id": "test",
      "question": "Test input:",
      "input_type": "input",
      "actions": [
        {
          "type": "custom",
          "property": "[[[ANS:test]]]"
        }
      ]
    }
  ]
}
```

### Test Edge Cases

- Empty inputs
- Special characters (`&`, `|`, `;`, `$`, etc.)
- Long paths
- Paths with spaces
- Non-existent paths
- Duplicate operations

### Manual Testing

```powershell
# Test placeholder function
. "./hooks/common.ps1"
$answers = @{ "name" = "Test" }
$result = Invoke-Replacement -Text "[[[ANS:name]]]" -Answers $answers
Write-Host "Result: $result"

# Test path resolution
$relative = "./template"
$absolute = Join-Path (Get-Location) $relative
Write-Host "Relative: $relative"
Write-Host "Absolute: $absolute"
```

---

## Code Style Summary

### Do's ✅

- Source `common.ps1` at the top
- Use `Invoke-Replacement` for all user-facing text
- Handle both absolute and relative paths
- Create parent directories when needed
- Use UTF-8 encoding for files
- Provide clear, colored feedback
- Use try-catch for error handling
- Validate inputs before processing
- Use PascalCase for variables
- Comment non-obvious logic

### Don'ts ❌

- Don't modify `generator.ps1` without good reason
- Don't modify existing hooks (create new ones)
- Don't use hardcoded paths
- Don't ignore errors
- Don't use aliases in scripts
- Don't process placeholders multiple times
- Don't forget error messages
- Don't skip path validation
- Don't use non-UTF8 encoding
- Don't execute unsanitized user input

---

## Example: Well-Written Hook

```powershell
# Action type: backup (create backup of files)
#
# Creates a timestamped backup of the specified file or directory.
# Supports both absolute and relative paths.
# Optionally compresses the backup.
#
# Example usage:
# {
#   "type": "backup",
#   "source": "./project",
#   "destination": "./backups",
#   "compress": true
# }

. "$PSScriptRoot/common.ps1"

function Invoke-BackupAction {
    param(
        [object]$Action,
        [hashtable]$Answers
    )

    Write-Host "  [Backup] Creating backup..." -ForegroundColor Cyan

    # 1. Process placeholders
    $source = Invoke-Replacement -Text $Action.source -Answers $Answers
    $destination = Invoke-Replacement -Text $Action.destination -Answers $Answers

    # 2. Resolve paths
    if (-not [System.IO.Path]::IsPathRooted($source)) {
        $source = Join-Path (Get-Location) $source
    }
    if (-not [System.IO.Path]::IsPathRooted($destination)) {
        $destination = Join-Path (Get-Location) $destination
    }

    # 3. Validate source exists
    if (-not (Test-Path $source)) {
        Write-Host "    ✗ Source not found: $source" -ForegroundColor Red
        throw "Backup source not found: $source"
    }

    # 4. Create destination directory
    if (-not (Test-Path $destination)) {
        New-Item -ItemType Directory -Path $destination -Force | Out-Null
    }

    # 5. Generate backup name with timestamp
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $sourceName = Split-Path -Leaf $source
    $backupName = "$sourceName-$timestamp"

    # 6. Perform backup
    try {
        if ($Action.compress) {
            # Create ZIP archive
            $backupPath = Join-Path $destination "$backupName.zip"
            Compress-Archive -Path $source -DestinationPath $backupPath -Force
            Write-Host "    ✓ Compressed backup: $backupPath" -ForegroundColor Green
        } else {
            # Copy directory/file
            $backupPath = Join-Path $destination $backupName
            Copy-Item -Path $source -Destination $backupPath -Recurse -Force
            Write-Host "    ✓ Backup created: $backupPath" -ForegroundColor Green
        }

        Write-Host "  ✓ Backup completed" -ForegroundColor Green
    } catch {
        Write-Host "    ✗ Backup failed: $_" -ForegroundColor Red
        Write-Host "    ℹ Check source path and destination permissions" -ForegroundColor Yellow
        throw
    }
}
```
