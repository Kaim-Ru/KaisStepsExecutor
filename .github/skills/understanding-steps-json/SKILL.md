---
name: understanding-steps-json
description: Learn the structure and schema of steps.json configuration file, including step properties, input types, action types, and conditional execution
---

# Skill: Understanding steps.json

## Overview

This skill teaches AI agents how to read, understand, and work with the `steps.json` configuration file, which defines the entire workflow of the automation tool.

---

## JSON Schema

```json
{
  "steps": [
    {
      "question_id": "string (optional)",
      "question": "string (optional)",
      "input_type": "input|select|multiselect (optional, default: input)",
      "options": [
        "array of strings (optional, required for select/multiselect)"
      ],
      "actions": [
        {
          "type": "execute|replace|copy|symlink|mkdir",
          "conditions": [
            {
              "question_id": "string",
              "ans": "string|object|array"
            }
          ]
          // Type-specific properties...
        }
      ]
    }
  ]
}
```

---

## Step Properties

### Core Properties

| Property      | Type   | Required | Description                                                           |
| ------------- | ------ | -------- | --------------------------------------------------------------------- |
| `question_id` | string | No       | Unique identifier for the question. Used to reference answers         |
| `question`    | string | No       | Question text to display to the user                                  |
| `input_type`  | string | No       | Type of input: `input`, `select`, or `multiselect` (default: `input`) |
| `options`     | array  | No       | Array of choices for `select`/`multiselect` types                     |
| `actions`     | array  | No       | Array of actions to execute for this step                             |

### Important Notes

- If `question_id` is omitted, the question is skipped and only actions are executed
- If `input_type` is invalid or hook file is missing, the step is skipped
- Both `question` and `actions` are optional
- Steps are executed sequentially in the order they appear

---

## Input Types

### 1. input - Text Input

**Hook File**: `hooks/input.ps1`

Simple text input from the user.

**Example:**

```json
{
  "question_id": "project_name",
  "question": "Enter project name:",
  "input_type": "input"
}
```

**Implementation**:

- Function: `Get-UserInput` with parameters `$Question`, `$Answers`
- Returns: String (user's input)

### 2. select - Single Selection

**Hook File**: `hooks/select.ps1`

User selects one option from a list.

**Example:**

```json
{
  "question_id": "framework",
  "question": "Which framework?",
  "input_type": "select",
  "options": ["React", "Vue", "Angular"]
}
```

**Implementation**:

- Function: `Get-UserInput` with parameters `$Question`, `$Options`, `$Answers`
- Returns: String (selected option text)
- Options are numbered and displayed to the user

### 3. multiselect - Multiple Selection

**Hook File**: `hooks/multiselect.ps1`

User selects multiple options from a list.

**Example:**

```json
{
  "question_id": "features",
  "question": "Select features:",
  "input_type": "multiselect",
  "options": ["TypeScript", "ESLint", "Jest", "Prettier"]
}
```

**Implementation**:

- Function: `Get-UserInput` with parameters `$Question`, `$Options`, `$Answers`
- Returns: String (comma-separated values like "TypeScript, ESLint, Jest")
- User enters space-separated numbers (e.g., "1 3 4")

---

## Action Types

### 1. execute - Execute PowerShell Command

**Hook File**: `hooks/execute.ps1`

**Properties:**

- `command` (string, required): PowerShell command to execute
- `conditions` (array, optional): Conditions to check before execution

**Example:**

```json
{
  "type": "execute",
  "command": "Write-Host 'Project: [[[ANS:project_name]]]'",
  "conditions": [{ "question_id": "project_name", "ans": { "regex": "^my" } }]
}
```

### 2. replace - Replace Strings in Files

**Hook File**: `hooks/replace.ps1`

**Properties:**

- `files` (array or object, required): File patterns to process
- `target` (string/object/array, required): String(s) to replace
- `value` (string, required): Replacement value
- `conditions` (array, optional): Conditions to check before execution

**Files Format:**

```json
// Array format (simple)
"files": ["file1.txt", "**/*.js"]

// Object format (with exclude)
"files": {
  "include": ["./template/**/*.txt"],
  "exclude": ["**/node_modules/**"]
}
```

**Target Format:**

```json
// String match
"target": "[[[PROJECT_NAME]]]"

// Regex match
"target": { "regex": "\\bOLD_NAME\\b" }

// Multiple strings (match any)
"target": ["[[[NAME1]]]", "[[[NAME2]]]"]
```

**Wildcard Support:**

- `*`: Matches any characters within a directory level
- `**`: Matches any characters across multiple directory levels
- `?`: Matches a single character

**Example:**

```json
{
  "type": "replace",
  "files": {
    "include": ["./template/**/*.txt"],
    "exclude": ["**/node_modules/**"]
  },
  "target": "[[[PROJECT_NAME]]]",
  "value": "[[[ANS:project_name]]]"
}
```

### 3. copy - Copy Files/Folders

**Hook File**: `hooks/copy.ps1`

**Properties:**

- `source` (string, required): Source file or folder path (absolute or relative)
- `destination` (string, required): Destination path (absolute or relative)
- `conditions` (array, optional): Conditions to check before execution

**Path Behavior:**

- If `destination` ends with `/` or `\`, source is copied into that directory
- Otherwise, source is copied/renamed to the exact destination path
- If source is a directory and destination exists as a directory, source folder is copied into destination

**Example:**

```json
{
  "type": "copy",
  "source": "./template/config",
  "destination": "./my-project/"
}
```

### 4. symlink - Create Symbolic Link

**Hook File**: `hooks/symlink.ps1`

**Properties:**

- `source` (string, required): Target file or folder path (absolute or relative)
- `destination` (string, required): Link path (absolute or relative)
- `conditions` (array, optional): Conditions to check before execution

**Path Behavior:**

- If `destination` ends with `/` or `\`, link is created inside that directory
- Otherwise, link is created with the exact destination path

**⚠️ Important:** Administrator privileges are required on Windows to create symbolic links.

**Example:**

```json
{
  "type": "symlink",
  "source": "./template/shared",
  "destination": "./my-project/shared"
}
```

### 5. mkdir - Create Directory

**Hook File**: `hooks/mkdir.ps1`

**Properties:**

- `path` (string, required): Directory path to create (absolute or relative)
- `conditions` (array, optional): Conditions to check before execution

**Example:**

```json
{
  "type": "mkdir",
  "path": "./[[[ANS:project_name]]]/src"
}
```

---

## Conditional Execution

Actions can be conditionally executed based on user answers using the `conditions` array.

### Condition Structure

```json
{
  "conditions": [
    {
      "question_id": "string",
      "ans": "string|object|array"
    }
  ]
}
```

**Logic:** ALL conditions must be met (AND operation).

### Condition Types

#### 1. String Match

```json
{
  "question_id": "framework",
  "ans": "React"
}
```

Matches if the answer to `framework` exactly equals "React".

#### 2. Regex Match

```json
{
  "question_id": "project_name",
  "ans": { "regex": "^my-" }
}
```

Matches if the answer to `project_name` starts with "my-".

#### 3. Array Match (Any)

```json
{
  "question_id": "framework",
  "ans": ["React", "Vue"]
}
```

Matches if the answer to `framework` is either "React" OR "Vue".

#### 4. With Placeholders

```json
{
  "question_id": "confirm_name",
  "ans": "[[[ANS:project_name]]]"
}
```

Matches if `confirm_name` equals the value of `project_name`.

### Multiselect Condition

For multiselect answers (comma-separated), use regex to check if answer contains the option:

```json
{
  "question_id": "features",
  "ans": { "regex": "TypeScript" }
}
```

This matches if "TypeScript" appears anywhere in the comma-separated list.

---

## Path Handling

### Absolute vs Relative Paths

- **Absolute paths**: Start with drive letter on Windows (e.g., `D:/path`) or `/` on Unix
- **Relative paths**: Resolved relative to current working directory (where `generator.ps1` is executed)

### Path Separators

Both `/` and `\` are supported as path separators. PowerShell handles both on Windows.

### Trailing Slashes

For `copy` and `symlink` actions:

- Path ending with `/` or `\`: Treated as a directory, source is copied/linked INTO it
- Path without trailing slash: Treated as exact destination path

---

## Examples

### Basic Question and Action

```json
{
  "steps": [
    {
      "question_id": "name",
      "question": "Enter your name:",
      "input_type": "input",
      "actions": [
        {
          "type": "execute",
          "command": "Write-Host 'Hello, [[[ANS:name]]]!'"
        }
      ]
    }
  ]
}
```

### Selection with Conditional Actions

```json
{
  "steps": [
    {
      "question_id": "framework",
      "question": "Choose a framework:",
      "input_type": "select",
      "options": ["React", "Vue", "Angular"]
    },
    {
      "actions": [
        {
          "type": "execute",
          "command": "npm install react react-dom",
          "conditions": [{ "question_id": "framework", "ans": "React" }]
        },
        {
          "type": "execute",
          "command": "npm install vue",
          "conditions": [{ "question_id": "framework", "ans": "Vue" }]
        }
      ]
    }
  ]
}
```

### Copy Template and Replace

```json
{
  "steps": [
    {
      "question_id": "app_name",
      "question": "Enter application name:",
      "input_type": "input",
      "actions": [
        {
          "type": "copy",
          "source": "./template",
          "destination": "./[[[ANS:app_name]]]/"
        },
        {
          "type": "replace",
          "files": {
            "include": ["./[[[ANS:app_name]]]/**/*.txt"],
            "exclude": ["**/node_modules/**"]
          },
          "target": "[[[APP_NAME]]]",
          "value": "[[[ANS:app_name]]]"
        }
      ]
    }
  ]
}
```

---

## Common Mistakes

### 1. Forgetting question_id

❌ **Wrong:**

```json
{
  "question": "Enter name:",
  "actions": [
    {
      "type": "execute",
      "command": "echo [[[ANS:name]]]" // No question_id to reference!
    }
  ]
}
```

✅ **Correct:**

```json
{
  "question_id": "name",
  "question": "Enter name:",
  "actions": [
    {
      "type": "execute",
      "command": "echo [[[ANS:name]]]"
    }
  ]
}
```

### 2. Missing options for select/multiselect

❌ **Wrong:**

```json
{
  "question_id": "framework",
  "question": "Choose framework:",
  "input_type": "select"
  // Missing "options" array!
}
```

✅ **Correct:**

```json
{
  "question_id": "framework",
  "question": "Choose framework:",
  "input_type": "select",
  "options": ["React", "Vue", "Angular"]
}
```

### 3. Wrong condition for multiselect

❌ **Wrong:**

```json
{
  "question_id": "features",
  "input_type": "multiselect",
  "options": ["TypeScript", "ESLint"],
  "actions": [
    {
      "type": "execute",
      "command": "npm install typescript",
      "conditions": [
        { "question_id": "features", "ans": "TypeScript" } // Won't match!
      ]
    }
  ]
}
```

✅ **Correct:**

```json
{
  "conditions": [
    { "question_id": "features", "ans": { "regex": "TypeScript" } }
  ]
}
```

### 4. Incorrect file patterns

❌ **Wrong:**

```json
{
  "type": "replace",
  "files": "template/*.txt", // Should be array!
  "target": "OLD",
  "value": "NEW"
}
```

✅ **Correct:**

```json
{
  "type": "replace",
  "files": ["./template/*.txt"],
  "target": "OLD",
  "value": "NEW"
}
```

---

## Best Practices

1. **Use descriptive question_ids**: `project_name` instead of `q1`
2. **Order questions logically**: Ask fundamental questions before derived ones
3. **Group related actions**: Keep related operations in the same step
4. **Use placeholders extensively**: Avoid hardcoding values
5. **Test with minimal examples**: Start simple, then add complexity
6. **Use exclude patterns**: Filter out `node_modules`, `.git`, etc. in replace actions
7. **Provide clear question text**: Users should understand what's being asked
8. **Use meaningful options**: "Yes, use TypeScript" instead of just "Yes"
