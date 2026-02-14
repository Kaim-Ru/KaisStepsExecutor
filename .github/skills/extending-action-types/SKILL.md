---
name: extending-action-types
description: Create custom action type hooks to add new capabilities to the system (e.g., download files, create git repos, send HTTP requests)
---

# Skill: Extending Action Types

## Overview

This skill teaches AI agents how to create custom action type hooks to add new capabilities to the system (e.g., download files, create git repos, send HTTP requests).

---

## Action Type Hook Basics

### Hook File Structure

**Location**: `hooks/{action_type}.ps1`

**Required Function**: `Invoke-{ActionType}Action`

**Template**:

```powershell
# Action type: {type_name} ({description})

. "$PSScriptRoot/common.ps1"

function Invoke-{ActionType}Action {
    param(
        [object]$Action,
        [hashtable]$Answers
    )

    Write-Host "  [{ActionType}] Action description..." -ForegroundColor Cyan

    # Process placeholders in action properties
    $property = Invoke-Replacement -Text $Action.property -Answers $Answers

    try {
        # Your action logic here

        Write-Host "    ✓ Success detail" -ForegroundColor Green
        Write-Host "  ✓ Action completed" -ForegroundColor Green
    } catch {
        Write-Host "    ✗ Error: $_" -ForegroundColor Red
        throw
    }
}
```

---

## Creating Custom Action Types

### Example 1: Download File

**Requirement**: Download a file from a URL

**File**: `hooks/download.ps1`

```powershell
# Action type: download (download file from URL)

. "$PSScriptRoot/common.ps1"

function Invoke-DownloadAction {
    param(
        [object]$Action,
        [hashtable]$Answers
    )

    Write-Host "  [Download] Downloading file..." -ForegroundColor Cyan

    # Process placeholders in properties
    $url = Invoke-Replacement -Text $Action.url -Answers $Answers
    $destination = Invoke-Replacement -Text $Action.destination -Answers $Answers

    # Resolve destination path
    if (-not [System.IO.Path]::IsPathRooted($destination)) {
        $destination = Join-Path (Get-Location) $destination
    }

    # Create parent directory if it doesn't exist
    $parentDir = Split-Path -Parent $destination
    if ($parentDir -and -not (Test-Path $parentDir)) {
        New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
    }

    try {
        Write-Host "  > Downloading from: $url" -ForegroundColor Gray
        Invoke-WebRequest -Uri $url -OutFile $destination -ErrorAction Stop
        Write-Host "    ✓ Downloaded to: $destination" -ForegroundColor Green
        Write-Host "  ✓ Download completed" -ForegroundColor Green
    } catch {
        Write-Host "    ✗ Download failed: $_" -ForegroundColor Red
        throw
    }
}
```

**Usage in steps.json**:

```json
{
  "type": "download",
  "url": "https://example.com/file.zip",
  "destination": "./downloads/file.zip"
}
```

---

### Example 2: Git Initialize

**Requirement**: Initialize git repository with optional remote

**File**: `hooks/gitinit.ps1`

```powershell
# Action type: gitinit (initialize git repository)

. "$PSScriptRoot/common.ps1"

function Invoke-GitinitAction {
    param(
        [object]$Action,
        [hashtable]$Answers
    )

    Write-Host "  [GitInit] Initializing git repository..." -ForegroundColor Cyan

    # Process placeholders
    $path = if ($Action.path) {
        Invoke-Replacement -Text $Action.path -Answers $Answers
    } else {
        Get-Location
    }

    # Resolve path
    if (-not [System.IO.Path]::IsPathRooted($path)) {
        $path = Join-Path (Get-Location) $path
    }

    try {
        # Initialize repository
        Push-Location $path

        if (Test-Path ".git") {
            Write-Host "    ℹ Git repository already initialized" -ForegroundColor Yellow
        } else {
            git init 2>&1 | Out-Null
            Write-Host "    ✓ Repository initialized" -ForegroundColor Green
        }

        # Add remote if specified
        if ($Action.remote) {
            $remote = Invoke-Replacement -Text $Action.remote -Answers $Answers
            git remote add origin $remote 2>&1 | Out-Null
            Write-Host "    ✓ Remote added: $remote" -ForegroundColor Green
        }

        Pop-Location
        Write-Host "  ✓ Git initialization completed" -ForegroundColor Green
    } catch {
        Pop-Location
        Write-Host "    ✗ Git initialization failed: $_" -ForegroundColor Red
        throw
    }
}
```

**Usage**:

```json
{
  "type": "gitinit",
  "path": "./[[[ANS:project_name]]]",
  "remote": "https://github.com/user/[[[ANS:project_name]]].git"
}
```

---

### Example 3: Write File

**Requirement**: Create file with content

**File**: `hooks/writefile.ps1`

```powershell
# Action type: writefile (create file with content)

. "$PSScriptRoot/common.ps1"

function Invoke-WritefileAction {
    param(
        [object]$Action,
        [hashtable]$Answers
    )

    Write-Host "  [WriteFile] Creating file..." -ForegroundColor Cyan

    # Process placeholders
    $path = Invoke-Replacement -Text $Action.path -Answers $Answers
    $content = Invoke-Replacement -Text $Action.content -Answers $Answers

    # Resolve path
    if (-not [System.IO.Path]::IsPathRooted($path)) {
        $path = Join-Path (Get-Location) $path
    }

    # Create parent directory if needed
    $parentDir = Split-Path -Parent $path
    if ($parentDir -and -not (Test-Path $parentDir)) {
        New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
    }

    try {
        Set-Content -Path $path -Value $content -Encoding UTF8 -NoNewline
        Write-Host "    ✓ File created: $path" -ForegroundColor Green
        Write-Host "  ✓ Write completed" -ForegroundColor Green
    } catch {
        Write-Host "    ✗ Failed to write file: $_" -ForegroundColor Red
        throw
    }
}
```

**Usage**:

```json
{
  "type": "writefile",
  "path": "./[[[ANS:project_name]]]/README.md",
  "content": "# [[[ANS:project_name]]]\n\nProject description here."
}
```

---

### Example 4: HTTP Request

**Requirement**: Send HTTP POST request

**File**: `hooks/httprequest.ps1`

```powershell
# Action type: httprequest (send HTTP request)

. "$PSScriptRoot/common.ps1"

function Invoke-HttprequestAction {
    param(
        [object]$Action,
        [hashtable]$Answers
    )

    Write-Host "  [HttpRequest] Sending HTTP request..." -ForegroundColor Cyan

    # Process placeholders
    $url = Invoke-Replacement -Text $Action.url -Answers $Answers
    $method = if ($Action.method) { $Action.method } else { "GET" }

    $body = if ($Action.body) {
        Invoke-Replacement -Text $Action.body -Answers $Answers
    } else {
        $null
    }

    try {
        Write-Host "  > $method $url" -ForegroundColor Gray

        $params = @{
            Uri = $url
            Method = $method
            ErrorAction = 'Stop'
        }

        if ($body) {
            $params.Body = $body
            $params.ContentType = 'application/json'
        }

        $response = Invoke-RestMethod @params

        Write-Host "    ✓ Request successful" -ForegroundColor Green

        # Optionally save response
        if ($Action.output) {
            $outputPath = Invoke-Replacement -Text $Action.output -Answers $Answers
            if (-not [System.IO.Path]::IsPathRooted($outputPath)) {
                $outputPath = Join-Path (Get-Location) $outputPath
            }
            $response | ConvertTo-Json | Set-Content -Path $outputPath -Encoding UTF8
            Write-Host "    ✓ Response saved to: $outputPath" -ForegroundColor Green
        }

        Write-Host "  ✓ HTTP request completed" -ForegroundColor Green
    } catch {
        Write-Host "    ✗ HTTP request failed: $_" -ForegroundColor Red
        throw
    }
}
```

**Usage**:

```json
{
  "type": "httprequest",
  "method": "POST",
  "url": "https://api.example.com/projects",
  "body": "{\"name\": \"[[[ANS:project_name]]]\", \"owner\": \"[[[ANS:user]]]\"}",
  "output": "./response.json"
}
```

---

### Example 5: Archive (Compress)

**Requirement**: Create ZIP archive

**File**: `hooks/archive.ps1`

```powershell
# Action type: archive (create ZIP archive)

. "$PSScriptRoot/common.ps1"

function Invoke-ArchiveAction {
    param(
        [object]$Action,
        [hashtable]$Answers
    )

    Write-Host "  [Archive] Creating archive..." -ForegroundColor Cyan

    # Process placeholders
    $source = Invoke-Replacement -Text $Action.source -Answers $Answers
    $destination = Invoke-Replacement -Text $Action.destination -Answers $Answers

    # Resolve paths
    if (-not [System.IO.Path]::IsPathRooted($source)) {
        $source = Join-Path (Get-Location) $source
    }
    if (-not [System.IO.Path]::IsPathRooted($destination)) {
        $destination = Join-Path (Get-Location) $destination
    }

    # Validate source exists
    if (-not (Test-Path $source)) {
        Write-Host "    ✗ Source not found: $source" -ForegroundColor Red
        throw "Archive source not found: $source"
    }

    # Create parent directory for destination
    $parentDir = Split-Path -Parent $destination
    if ($parentDir -and -not (Test-Path $parentDir)) {
        New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
    }

    try {
        # Remove existing archive if overwrite is enabled
        if ((Test-Path $destination) -and $Action.overwrite) {
            Remove-Item -Path $destination -Force
        }

        Compress-Archive -Path $source -DestinationPath $destination -Force
        Write-Host "    ✓ Archive created: $destination" -ForegroundColor Green
        Write-Host "  ✓ Archive completed" -ForegroundColor Green
    } catch {
        Write-Host "    ✗ Archive failed: $_" -ForegroundColor Red
        throw
    }
}
```

**Usage**:

```json
{
  "type": "archive",
  "source": "./[[[ANS:project_name]]]",
  "destination": "./releases/[[[ANS:project_name]]]-v1.0.zip",
  "overwrite": true
}
```

---

### Example 6: Delete

**Requirement**: Delete files or folders

**File**: `hooks/delete.ps1`

```powershell
# Action type: delete (delete files or folders)

. "$PSScriptRoot/common.ps1"

function Invoke-DeleteAction {
    param(
        [object]$Action,
        [hashtable]$Answers
    )

    Write-Host "  [Delete] Deleting..." -ForegroundColor Cyan

    # Process placeholders
    $path = Invoke-Replacement -Text $Action.path -Answers $Answers

    # Resolve path
    if (-not [System.IO.Path]::IsPathRooted($path)) {
        $path = Join-Path (Get-Location) $path
    }

    if (-not (Test-Path $path)) {
        Write-Host "    ℹ Path not found (already deleted?): $path" -ForegroundColor Yellow
        Write-Host "  ✓ Delete completed (nothing to delete)" -ForegroundColor Green
        return
    }

    try {
        # Confirm if required
        if ($Action.confirm) {
            Write-Host "  ⚠ About to delete: $path" -ForegroundColor Yellow
            $confirmation = Read-Host "  Are you sure? (yes/no)"
            if ($confirmation -ne 'yes') {
                Write-Host "    ℹ Delete cancelled by user" -ForegroundColor Yellow
                return
            }
        }

        Remove-Item -Path $path -Recurse -Force
        Write-Host "    ✓ Deleted: $path" -ForegroundColor Green
        Write-Host "  ✓ Delete completed" -ForegroundColor Green
    } catch {
        Write-Host "    ✗ Delete failed: $_" -ForegroundColor Red
        throw
    }
}
```

**Usage**:

```json
{
  "type": "delete",
  "path": "./temp_[[[ANS:session_id]]]",
  "confirm": false
}
```

---

## Naming Conventions

### File Names

- Lowercase, no spaces: `download.ps1`, `gitinit.ps1`
- Match action type exactly
- Use descriptive names: `httprequest.ps1` not `http.ps1`

### Function Names

- Pattern: `Invoke-{ActionType}Action`
- ActionType in PascalCase: `Invoke-DownloadAction`, `Invoke-GitinitAction`
- Must match the pattern exactly for generator.ps1 to find it

**Mapping**:

```
Action type in JSON -> Function name
"download"          -> Invoke-DownloadAction
"gitinit"           -> Invoke-GitinitAction
"writefile"         -> Invoke-WritefileAction
"httprequest"       -> Invoke-HttprequestAction
```

### Variable Names

- Use PascalCase: `$SourcePath`, `$DestinationPath`
- Be consistent with existing hooks

---

## Action Development Checklist

When creating a new action type hook:

- [ ] Create file `hooks/{type}.ps1`
- [ ] Source `common.ps1` at the top
- [ ] Define `Invoke-{Type}Action` function (PascalCase)
- [ ] Accept parameters: `$Action`, `$Answers`
- [ ] Process all action properties with `Invoke-Replacement`
- [ ] Handle both absolute and relative paths
- [ ] Create parent directories if needed
- [ ] Implement proper error handling with try-catch
- [ ] Provide clear feedback messages
- [ ] Use standard color scheme (Cyan, Green, Red, Yellow, Gray)
- [ ] Validate inputs before processing
- [ ] Test with test configuration file
- [ ] Document in README.md
- [ ] Add usage examples

---

## Path Handling Best Practices

### Always Support Both Absolute and Relative Paths

```powershell
# Resolve path
if (-not [System.IO.Path]::IsPathRooted($path)) {
    $path = Join-Path (Get-Location) $path
}
```

### Create Parent Directories

```powershell
$parentDir = Split-Path -Parent $path
if ($parentDir -and -not (Test-Path $parentDir)) {
    New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
}
```

### Validate Paths Exist (for source paths)

```powershell
if (-not (Test-Path $source)) {
    Write-Host "    ✗ Source not found: $source" -ForegroundColor Red
    throw "Source not found: $source"
}
```

---

## Error Handling Best Practices

### Use Try-Catch Blocks

```powershell
try {
    # Operation that might fail
    Write-Host "    ✓ Success message" -ForegroundColor Green
    Write-Host "  ✓ Action completed" -ForegroundColor Green
} catch {
    Write-Host "    ✗ Error message: $_" -ForegroundColor Red
    throw  # Re-throw to stop execution
}
```

### Provide Helpful Error Messages

```powershell
catch {
    Write-Host "    ✗ Failed to download file: $_" -ForegroundColor Red
    Write-Host "    ℹ Check network connection and URL validity" -ForegroundColor Yellow
    throw
}
```

### Handle Expected Conditions

```powershell
if (Test-Path $destination) {
    Write-Host "    ℹ File already exists: $destination" -ForegroundColor Yellow

    if ($Action.overwrite) {
        Remove-Item -Path $destination -Force
    } else {
        Write-Host "    ℹ Skipping (overwrite not enabled)" -ForegroundColor Yellow
        return
    }
}
```

---

## Output Message Standards

### Color Scheme

- **Cyan**: Action start messages
- **Green**: Success messages
- **Red**: Errors
- **Yellow**: Warnings, skipped items
- **Gray**: Secondary information (commands, URLs)

### Symbol Usage

- `✓`: Success, completion
- `✗`: Error, failure
- `ℹ`: Information, already exists
- `⚠`: Warning
- `>`: Command or secondary information

### Message Format

```powershell
Write-Host "  [ActionType] Starting action..." -ForegroundColor Cyan
Write-Host "  > Additional info or command" -ForegroundColor Gray
Write-Host "    ✓ Specific success detail" -ForegroundColor Green
Write-Host "    ℹ Information message" -ForegroundColor Yellow
Write-Host "  ✓ Action completed" -ForegroundColor Green
```

**Example**:

```powershell
Write-Host "  [Download] Downloading file..." -ForegroundColor Cyan
Write-Host "  > URL: https://example.com/file.zip" -ForegroundColor Gray
Write-Host "    ✓ Downloaded: 1.5 MB" -ForegroundColor Green
Write-Host "  ✓ Download completed" -ForegroundColor Green
```

---

## Testing Action Types

### Test Configuration

Create `test-actions.json`:

```json
{
  "steps": [
    {
      "question_id": "filename",
      "question": "Enter filename:",
      "input_type": "input",
      "actions": [
        {
          "type": "writefile",
          "path": "./test/[[[ANS:filename]]].txt",
          "content": "Test content for [[[ANS:filename]]]"
        },
        {
          "type": "archive",
          "source": "./test",
          "destination": "./test.zip"
        },
        {
          "type": "delete",
          "path": "./test",
          "confirm": false
        }
      ]
    }
  ]
}
```

Run:

```powershell
.\generator.ps1 -StepPath "test-actions.json"
```

---

## Common Mistakes

### 1. Wrong Function Name

❌ **Wrong:**

```powershell
function Invoke-Download {  # Missing "Action" suffix
    param([object]$Action, [hashtable]$Answers)
}
```

✅ **Correct:**

```powershell
function Invoke-DownloadAction {  # Correct pattern
    param([object]$Action, [hashtable]$Answers)
}
```

### 2. Not Processing Placeholders

❌ **Wrong:**

```powershell
$url = $Action.url  # Not processed!
Invoke-WebRequest -Uri $url -OutFile "file.zip"
```

✅ **Correct:**

```powershell
$url = Invoke-Replacement -Text $Action.url -Answers $Answers
Invoke-WebRequest -Uri $url -OutFile "file.zip"
```

### 3. Missing common.ps1

❌ **Wrong:**

```powershell
# Missing: . "$PSScriptRoot/common.ps1"

function Invoke-DownloadAction {
    $url = Invoke-Replacement -Text $Action.url -Answers $Answers  # Function not available!
}
```

✅ **Correct:**

```powershell
. "$PSScriptRoot/common.ps1"

function Invoke-DownloadAction {
    $url = Invoke-Replacement -Text $Action.url -Answers $Answers
}
```

### 4. Not Handling Relative Paths

❌ **Wrong:**

```powershell
$path = $Action.path  # Could be relative!
New-Item -ItemType Directory -Path $path  # May fail or create in wrong location
```

✅ **Correct:**

```powershell
$path = Invoke-Replacement -Text $Action.path -Answers $Answers
if (-not [System.IO.Path]::IsPathRooted($path)) {
    $path = Join-Path (Get-Location) $path
}
New-Item -ItemType Directory -Path $path
```

### 5. Poor Error Messages

❌ **Wrong:**

```powershell
catch {
    Write-Host "Error: $_" -ForegroundColor Red
    throw
}
```

✅ **Correct:**

```powershell
catch {
    Write-Host "    ✗ Failed to download file: $_" -ForegroundColor Red
    Write-Host "    ℹ Verify URL is correct and accessible" -ForegroundColor Yellow
    throw
}
```

---

## Best Practices Summary

1. ✅ Always source `common.ps1`
2. ✅ Process all properties with `Invoke-Replacement`
3. ✅ Handle both absolute and relative paths
4. ✅ Create parent directories when needed
5. ✅ Use try-catch for error handling
6. ✅ Provide clear, helpful error messages
7. ✅ Follow color and symbol conventions
8. ✅ Validate inputs before processing
9. ✅ Test with various placeholder combinations
10. ✅ Document in README.md

---

## Complete Example: Send Email Action

**File**: `hooks/sendemail.ps1`

```powershell
# Action type: sendemail (send email via SMTP)

. "$PSScriptRoot/common.ps1"

function Invoke-SendemailAction {
    param(
        [object]$Action,
        [hashtable]$Answers
    )

    Write-Host "  [SendEmail] Sending email..." -ForegroundColor Cyan

    # Process placeholders
    $to = Invoke-Replacement -Text $Action.to -Answers $Answers
    $subject = Invoke-Replacement -Text $Action.subject -Answers $Answers
    $body = Invoke-Replacement -Text $Action.body -Answers $Answers
    $from = Invoke-Replacement -Text $Action.from -Answers $Answers
    $smtpServer = Invoke-Replacement -Text $Action.smtp -Answers $Answers

    try {
        Write-Host "  > To: $to" -ForegroundColor Gray
        Write-Host "  > Subject: $subject" -ForegroundColor Gray

        $emailParams = @{
            To = $to
            From = $from
            Subject = $subject
            Body = $body
            SmtpServer = $smtpServer
        }

        if ($Action.port) {
            $emailParams.Port = $Action.port
        }

        Send-MailMessage @emailParams

        Write-Host "    ✓ Email sent successfully" -ForegroundColor Green
        Write-Host "  ✓ Send email completed" -ForegroundColor Green
    } catch {
        Write-Host "    ✗ Failed to send email: $_" -ForegroundColor Red
        Write-Host "    ℹ Check SMTP server settings" -ForegroundColor Yellow
        throw
    }
}
```

**Usage**:

```json
{
  "type": "sendemail",
  "from": "noreply@example.com",
  "to": "[[[ANS:user_email]]]",
  "subject": "Project [[[ANS:project_name]]] created",
  "body": "Your project has been successfully created.",
  "smtp": "smtp.example.com",
  "port": 587
}
```

---

## Related Skills

- [Understanding steps.json](../understanding-steps-json/SKILL.md) - Learn action type usage
- [Working with Placeholders](../working-with-placeholders/SKILL.md) - Process properties
- [Coding Best Practices](../coding-best-practices/SKILL.md) - Follow coding standards
- [Debugging and Testing](../debugging-and-testing/SKILL.md) - Test your hooks
