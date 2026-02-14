# PowerShell Steps Executor

[日本語版はこちら (Japanese)](README.ja.md)

An interactive PowerShell automation tool that executes workflows defined in JSON. Supports questions, conditional actions, file operations, and extensible hooks.

## Usage

```powershell
.\generator.ps1                           # Use default steps.json
.\generator.ps1 -StepPath "custom.json"  # Use custom config
```

## Configuration

**Basic Structure:**

```json
{
  "steps": [
    {
      "question_id": "project_name",
      "question": "Enter project name",
      "input_type": "input",
      "actions": [...]
    }
  ]
}
```

**Step Properties:**

- `question_id` - Unique ID to reference the answer (optional)
- `question` - Question text (optional)
- `input_type` - `input`, `select`, or `multiselect` (default: `input`)
- `options` - Array of choices for select/multiselect
- `actions` - Array of actions to execute

**Actions:**

1. **execute** - Execute PowerShell commands

   ```json
   { "type": "execute", "command": "git init" }
   ```

2. **replace** - Replace strings in files (supports wildcards)

   ```json
   {
     "type": "replace",
     "files": ["./template/**/*.txt"],
     "target": "[[[OLD]]]",
     "value": "[[[ANS:project_name]]]"
   }
   ```

   - `files`: Patterns (array or `{include: [...], exclude: [...]}`), supports `*`, `**`, `?`
   - `target`: String, regex `{"regex": "..."}`, or array (any match)
   - `value`: Replacement value

3. **copy** - Copy files/folders

   ```json
   { "type": "copy", "source": "./template", "destination": "./output/" }
   ```

4. **symlink** - Create symbolic link (requires admin on Windows)

   ```json
   { "type": "symlink", "source": "./config", "destination": "./link" }
   ```

5. **mkdir** - Create directory
   ```json
   { "type": "mkdir", "path": "./[[[ANS:project_name]]]/src" }
   ```

**Conditions:**

**Conditions:**

Actions execute only when conditions are met (AND logic):

```json
{
  "conditions": [
    { "question_id": "use_git", "ans": "Yes" },
    { "question_id": "framework", "ans": ["React", "Vue"] }, // Any match (OR)
    { "question_id": "name", "ans": { "regex": "^my-" } } // Regex match
  ],
  "type": "execute",
  "command": "npm install"
}
```

**Placeholders:**

- `[[[ANS:question_id]]]` - Reference answer
- `[[[UUIDv4]]]` - Generate unique UUID
- `\[[[...]]]` - Escape (use `\\[[[...]]]` in JSON)

Placeholders work in: `question`, `options`, `command`, `target`, `value`, `source`, `destination`, `path`, and condition `ans` values.

## Example

```json
{
  "steps": [
    {
      "question_id": "name",
      "question": "Project name?",
      "input_type": "input",
      "actions": [
        { "type": "mkdir", "path": "./[[[ANS:name]]]" },
        {
          "type": "replace",
          "files": ["./template/**"],
          "target": "[[[NAME]]]",
          "value": "[[[ANS:name]]]"
        },
        {
          "type": "copy",
          "source": "./template",
          "destination": "./[[[ANS:name]]]/"
        }
      ]
    },
    {
      "question_id": "typescript",
      "question": "Use TypeScript?",
      "input_type": "select",
      "options": ["Yes", "No"],
      "actions": [
        {
          "conditions": [{ "question_id": "typescript", "ans": "Yes" }],
          "type": "execute",
          "command": "npm install -D typescript"
        }
      ]
    }
  ]
}
```

## Extensibility

All input types and actions are **hooks** in `./hooks/`:

**Built-in:**

- Input: `input.ps1`, `select.ps1`, `multiselect.ps1`
- Actions: `execute.ps1`, `replace.ps1`, `copy.ps1`, `symlink.ps1`, `mkdir.ps1`

**Custom Hook:**

Create `hooks/{type}.ps1`:

```powershell
. "$PSScriptRoot/common.ps1"

# For input types
function Get-UserInput {
    param([string]$Question, [array]$Options, [hashtable]$Answers)
    # Implementation
    return $result
}

# For action types
function Invoke-CustomAction {
    param([object]$Action, [hashtable]$Answers)
    $value = Invoke-Replacement -Text $Action.property -Answers $Answers
    # Implementation
}
```

## Documentation

For developers and AI agents, see [AGENTS.md](AGENTS.md) for architecture, coding conventions, and extension guides.

## License

MIT
