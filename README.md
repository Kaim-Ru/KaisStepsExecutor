# PowerShell Steps Executor

A PowerShell script that sequentially executes steps, questions, and associated actions defined in steps.json.

## Overview

This script executes processes defined in a JSON file (default: `steps.json`) in order. It supports user questions, conditional branching, file replacement, copying, symbolic link creation, command execution, and more.

## Usage

```powershell
.\generate.ps1
```

To use a custom configuration file:

```powershell
.\generate.ps1 -StepPath "custom-steps.json"
```

## steps.json Structure

### Basic Structure

```json
{
  "steps": [
    {
      "question_id": "project_name",
      "question": "Please enter the project name",
      "type": "input",
      "actions": [...]
    }
  ]
}
```

### Step Properties

| Property      | Required | Description                                                                     |
| ------------- | -------- | ------------------------------------------------------------------------------- |
| `question_id` | No       | Question ID. Used to reference the answer. If omitted, the question is skipped  |
| `question`    | No       | Question text                                                                   |
| `type`        | No       | Question type. `input` (text input) or `select` (selection). Default is `input` |
| `options`     | No       | Array of choices for `type: "select"`                                           |
| `actions`     | No       | Array of actions to execute                                                     |

### Action Types

#### 1. execute - Execute Command

Executes a PowerShell command.

```json
{
  "type": "execute",
  "command": "git init",
  "conditions": [...]
}
```

#### 2. replace - Replace Strings in Files

Replaces strings in specified files. Supports wildcards.

```json
{
  "type": "replace",
  "files": ["./template/**/*.txt", "./config/*.json"],
  "target": "[[[PROJECT_NAME]]]",
  "value": "[[[ANS:project_name]]]",
  "conditions": [...]
}
```

- `files`: File patterns to replace (array or object with `include`/`exclude`). Supports wildcards (`*`, `**`). Both absolute and relative paths supported
- `target`: String to be replaced. Can also use:
  - String: `"[[[PROJECT_NAME]]]"` (simple string match)
  - Regex: `{ "regex": "Project-\\d+" }` (regex pattern match)
  - Array: `["[[[NAME1]]]", "[[[NAME2]]]"]` (match any of the strings)
- `value`: Replacement value

**Advanced `files` format:**

```json
{
  "type": "replace",
  "files": {
    "include": ["./template/**/*.txt"],
    "exclude": ["./template/test/**"]
  },
  "target": "[[[PROJECT_NAME]]]",
  "value": "[[[ANS:project_name]]]"
}
```

#### 3. copy - Copy Files/Folders

Copies files or folders.

```json
{
  "type": "copy",
  "source": "./template/README.txt",
  "destination": "./output/",
  "conditions": [...]
}
```

- `source`: Source file or folder (both absolute and relative paths supported)
- `destination`: Destination (both absolute and relative paths supported)

#### 4. symlink - Create Symbolic Link

Creates a symbolic link.

```json
{
  "type": "symlink",
  "source": "./template/config.txt",
  "destination": "./",
  "conditions": [...]
}
```

- `source`: Link source file or folder
- `destination`: Link destination

⚠️ **Note**: Administrator privileges may be required to create symbolic links on Windows.

### Conditional Branching

If you specify `conditions` for an action, it will only be executed when the conditions are met.

```json
{
  "conditions": [
    { "question_id": "use_git", "ans": "Yes" },
    { "question_id": "project_type", "ans": "Library" }
  ],
  "type": "execute",
  "command": "npm init -y"
}
```

All conditions must be met (AND condition).

**Advanced condition formats:**

- **String match**: `{ "question_id": "framework", "ans": "React" }`
- **Regex match**: `{ "question_id": "project_name", "ans": { "regex": "^my-" } }`
- **Multiple values (any)**: `{ "question_id": "framework", "ans": ["React", "Vue"] }`
- **With placeholders**: `{ "question_id": "name", "ans": "[[[ANS:prefix]]]_app" }`

```json
{
  "conditions": [
    { "question_id": "project_name", "ans": { "regex": "^my-" } },
    { "question_id": "framework", "ans": ["React", "Vue", "Angular"] }
  ],
  "type": "execute",
  "command": "npm install"
}
```

## Placeholders

Placeholders work in the following fields:

- `question` (question text)
- `options` (selection options)
- `command` (execute command)
- `target` and `value` (replace action)
- `source` and `destination` (copy/symlink actions)
- `ans` in `conditions` (condition values)

### [[[ANS:question_id]]] - Reference Answer

References the answer to a question.

```json
{
  "type": "replace",
  "target": "[[[PROJECT_NAME]]]",
  "value": "[[[ANS:project_name]]]"
}
```

### [[[UUIDv4]]] - Generate UUID

Automatically generates a UUID v4. A new UUID is generated for each occurrence.

```text
Project ID: [[[UUIDv4]]]
Session ID: [[[UUIDv4]]]
```

### Escaping

To treat a placeholder as a literal string, escape it with a backslash.

```json
{
  "type": "replace",
  "target": "PLACEHOLDER",
  "value": "\\[[[ANS:project_name]]]"
}
```

In JSON, backslashes must also be escaped, so write `\\[[[...]]]`.
As a result, the string `[[[ANS:project_name]]]` is output as is.

## Sample steps.json

```json
{
  "steps": [
    {
      "actions": [
        {
          "type": "execute",
          "command": "git init"
        }
      ]
    },
    {
      "question_id": "project_name",
      "question": "Please enter the project name",
      "type": "input",
      "actions": [
        {
          "type": "replace",
          "files": ["./template/**/*.txt"],
          "target": "[[[PROJECT_NAME]]]",
          "value": "[[[ANS:project_name]]]"
        },
        {
          "conditions": [{ "question_id": "project_name", "ans": "MyProject" }],
          "type": "execute",
          "command": "Write-Host 'Welcome to [[[ANS:project_name]]]!'"
        },
        {
          "type": "copy",
          "source": "./template/README.txt",
          "destination": "./"
        },
        {
          "type": "symlink",
          "source": "./template/config.txt",
          "destination": "./"
        }
      ]
    },
    {
      "question_id": "use_typescript",
      "question": "Do you want to use TypeScript?",
      "type": "select",
      "options": ["Yes", "No"],
      "actions": [
        {
          "conditions": [{ "question_id": "use_typescript", "ans": "Yes" }],
          "type": "execute",
          "command": "npm install --save-dev typescript"
        }
      ]
    }
  ]
}
```

## Execution Example

```powershell
PS> .\generate.ps1
==========================================
  PowerShell Steps Executor
==========================================

--- Step 1 ---
  [Execute] Running command...
  > git init
Initialized empty Git repository in D:/Project/.git/
  ✓ Execution completed

--- Step 2 ---

Please enter the project name: MyAwesomeProject
  Answer saved: 'MyAwesomeProject'

  [Replace] Replacing strings in files...
    ✓ D:\Project\template\README.txt
    ✓ D:\Project\template\package.json
  ✓ Processed 2 file(s)
  [Copy] Copying file/folder...
    ✓ D:\Project\template\README.txt -> D:\Project\
  ✓ Copy completed
  [Symlink] Creating symbolic link...
    ✓ D:\Project\template\config.txt -> D:\Project\config.txt
  ✓ Symbolic link created

--- Step 3 ---

Do you want to use TypeScript?
  1. Yes
  2. No
Please select (1-2): 1
  Answer saved: 'Yes'

  [Execute] Running command...
  > npm install --save-dev typescript
  ✓ Execution completed

==========================================
  ✓ All steps completed successfully!
==========================================
```

## Hook System (Extensibility)

All input types and action types are implemented as **hooks** in the `./hooks/` directory. This architecture makes it easy to add custom types without modifying the core script.

### Architecture

The system consists of:

- **generator.ps1**: Core orchestrator (loads and executes hooks)
- **hooks/common.ps1**: Shared utilities (`Invoke-Replacement`)
- **hooks/{type}.ps1**: Type-specific implementations

### Built-in Hooks

**Input Types:**

- `hooks/input.ps1` - Text input (default)
- `hooks/select.ps1` - Single selection from options

**Action Types:**

- `hooks/execute.ps1` - Execute PowerShell commands
- `hooks/replace.ps1` - String replacement in files
- `hooks/copy.ps1` - Copy files/folders
- `hooks/symlink.ps1` - Create symbolic links

### Creating Custom Hooks

#### Custom Input Type

Create `hooks/{type}.ps1` with a `Get-UserInput` function:

```powershell
# hooks/multiselect.ps1
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

    # Custom implementation here
    # Example: Allow multiple selections, return comma-separated values

    # Display options
    for ($i = 0; $i -lt $Options.Count; $i++) {
        Write-Host "  $($i + 1). $($Options[$i])"
    }

    $selected = Read-Host "Select multiple (e.g., 1,3,4)"
    # Process and return result...

    return $result
}
```

**Usage in steps.json:**

```json
{
  "question_id": "features",
  "question": "Select features",
  "input_type": "multiselect",
  "options": ["Auth", "Database", "API"]
}
```

#### Custom Action Type

Create `hooks/{type}.ps1` with an `Invoke-{Type}Action` function:

```powershell
# hooks/mkdir.ps1
. "$PSScriptRoot/common.ps1"

function Invoke-MkdirAction {
    param(
        [object]$Action,
        [hashtable]$Answers
    )

    Write-Host "  [Mkdir] Creating directory..." -ForegroundColor Cyan

    # Process placeholders
    $path = Invoke-Replacement -Text $Action.path -Answers $Answers

    # Resolve path
    if (-not [System.IO.Path]::IsPathRooted($path)) {
        $path = Join-Path (Get-Location) $path
    }

    # Create directory
    if (-not (Test-Path $path)) {
        New-Item -ItemType Directory -Path $path -Force | Out-Null
        Write-Host "    ✓ Created: $path" -ForegroundColor Green
    } else {
        Write-Host "    ℹ Already exists: $path" -ForegroundColor Yellow
    }
}
```

**Usage in steps.json:**

```json
{
  "type": "mkdir",
  "path": "./output/[[[ANS:project_name]]]"
}
```

### Hook Guidelines

1. **Always load common.ps1**: `. "$PSScriptRoot/common.ps1"`
2. **Use standard function signatures**:
   - Input: `Get-UserInput` with `$Question`, `$Options`, `$Answers`
   - Action: `Invoke-{Type}Action` with `$Action`, `$Answers`
3. **Process placeholders** using `Invoke-Replacement`
4. **Provide user feedback** with colored `Write-Host` messages
5. **Throw exceptions** on unrecoverable errors (will be caught by main script)

### Dependencies

- **generator.ps1** depends on: `hooks/common.ps1` (loaded at startup)
- All hooks depend on: `hooks/common.ps1` (for `Invoke-Replacement`)
- Hooks are loaded dynamically when needed (lazy loading)

## Features

- ✅ Steps without questions (can omit `question_id`)
- ✅ Text input and selection-style questions
- ✅ Conditional branching (AND evaluation of multiple conditions)
- ✅ Multiple file replacement with wildcards (`**/*.txt`, etc.)
- ✅ Placeholder replacement (answer reference, UUID generation, escaping)
- ✅ File/folder copying
- ✅ Symbolic link creation
- ✅ PowerShell command execution
- ✅ Support for both absolute and relative paths
- ✅ UTF8 encoding support
- ✅ Progress display with color output
- ✅ Error handling with detailed error messages

## License

MIT License

## Related Projects

- [pstest](../pstest/) - Similar project (with output destination management feature)
