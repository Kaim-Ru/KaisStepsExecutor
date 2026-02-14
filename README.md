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
.\generate.ps1 -ConfigPath "custom-steps.json"
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

- `files`: File patterns to replace (array). Supports wildcards (`*`, `**`). Both absolute and relative paths supported
- `target`: String to be replaced
- `value`: Replacement value

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

## Placeholders

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
