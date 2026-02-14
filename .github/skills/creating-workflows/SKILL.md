---
name: creating-workflows
description: Design and implement effective workflows in steps.json with common patterns, conditional branching, and multi-step processes
---

# Skill: Creating Workflows

## Overview

This skill teaches AI agents how to design and implement effective workflows in `steps.json`, including common patterns, conditional branching, and multi-step processes.

---

## Workflow Design Principles

### 1. Order Questions Logically

Ask fundamental questions before derived ones:

✅ **Good:**

```json
{
  "steps": [
    { "question_id": "project_name", "question": "Project name?" },
    { "question_id": "use_typescript", "question": "Use TypeScript?" },
    {
      "question_id": "tsconfig_strict",
      "question": "Enable strict mode?",
      "conditions": [{ "question_id": "use_typescript", "ans": "Yes" }]
    }
  ]
}
```

❌ **Bad:**

```json
{
  "steps": [
    { "question_id": "tsconfig_strict", "question": "Enable strict mode?" },
    { "question_id": "use_typescript", "question": "Use TypeScript?" }
  ]
}
```

### 2. Group Related Actions

Keep related operations in the same step:

```json
{
  "question_id": "project_name",
  "question": "Enter project name:",
  "actions": [
    { "type": "mkdir", "path": "./[[[ANS:project_name]]]" },
    {
      "type": "copy",
      "source": "./template",
      "destination": "./[[[ANS:project_name]]]/"
    },
    {
      "type": "replace",
      "files": ["./[[[ANS:project_name]]]/**/*.txt"],
      "target": "[[[PROJECT_NAME]]]",
      "value": "[[[ANS:project_name]]]"
    }
  ]
}
```

### 3. Use Meaningful Identifiers

- **question_id**: Descriptive and consistent (`project_name`, `use_typescript`)
- **Question text**: Clear and concise ("Enter project name:" not "Name?")
- **Options**: Self-explanatory ("Yes, use TypeScript" not just "Yes")

### 4. Minimize User Decisions

Don't ask unnecessary questions:

❌ **Over-asking:**

```json
{ "question": "Do you want to create a README?" },
{ "question": "Do you want to create a .gitignore?" },
{ "question": "Do you want to create a package.json?" }
```

✅ **Better:**

```json
{
  "question": "Select files to create:",
  "input_type": "multiselect",
  "options": ["README", ".gitignore", "package.json"]
}
```

---

## Common Workflow Patterns

### Pattern 1: Copy Template and Replace Placeholders

**Use Case**: Initialize project from template with custom values

```json
{
  "steps": [
    {
      "question_id": "app_name",
      "question": "Enter application name:",
      "input_type": "input"
    },
    {
      "question_id": "author",
      "question": "Enter author name:",
      "input_type": "input"
    },
    {
      "actions": [
        {
          "type": "copy",
          "source": "./template",
          "destination": "./[[[ANS:app_name]]]/"
        },
        {
          "type": "replace",
          "files": {
            "include": ["./[[[ANS:app_name]]]/**/*.{txt,json,md}"],
            "exclude": ["**/node_modules/**", "**/.git/**"]
          },
          "target": ["[[[APP_NAME]]]", "[[[AUTHOR]]]"],
          "value": "[[[ANS:app_name]]]"
        },
        {
          "type": "replace",
          "files": ["./[[[ANS:app_name]]]/**/*.{txt,json,md}"],
          "target": "[[[AUTHOR]]]",
          "value": "[[[ANS:author]]]"
        }
      ]
    }
  ]
}
```

### Pattern 2: Conditional Feature Installation

**Use Case**: Install optional features based on user selection

```json
{
  "steps": [
    {
      "question_id": "use_typescript",
      "question": "Use TypeScript?",
      "input_type": "select",
      "options": ["Yes", "No"]
    },
    {
      "actions": [
        {
          "type": "execute",
          "command": "npm install typescript @types/node --save-dev",
          "conditions": [{ "question_id": "use_typescript", "ans": "Yes" }]
        },
        {
          "type": "copy",
          "source": "./template/tsconfig.json",
          "destination": "./",
          "conditions": [{ "question_id": "use_typescript", "ans": "Yes" }]
        },
        {
          "type": "copy",
          "source": "./template/jsconfig.json",
          "destination": "./",
          "conditions": [{ "question_id": "use_typescript", "ans": "No" }]
        }
      ]
    }
  ]
}
```

### Pattern 3: Multi-Feature Selection

**Use Case**: User selects multiple features to include

```json
{
  "steps": [
    {
      "question_id": "features",
      "question": "Select features to include:",
      "input_type": "multiselect",
      "options": ["Linting (ESLint)", "Testing (Jest)", "Formatting (Prettier)"]
    },
    {
      "actions": [
        {
          "type": "execute",
          "command": "npm install eslint --save-dev",
          "conditions": [
            { "question_id": "features", "ans": { "regex": "Linting" } }
          ]
        },
        {
          "type": "copy",
          "source": "./template/.eslintrc.json",
          "destination": "./",
          "conditions": [
            { "question_id": "features", "ans": { "regex": "Linting" } }
          ]
        },
        {
          "type": "execute",
          "command": "npm install jest @types/jest --save-dev",
          "conditions": [
            { "question_id": "features", "ans": { "regex": "Testing" } }
          ]
        },
        {
          "type": "copy",
          "source": "./template/jest.config.js",
          "destination": "./",
          "conditions": [
            { "question_id": "features", "ans": { "regex": "Testing" } }
          ]
        },
        {
          "type": "execute",
          "command": "npm install prettier --save-dev",
          "conditions": [
            { "question_id": "features", "ans": { "regex": "Formatting" } }
          ]
        },
        {
          "type": "copy",
          "source": "./template/.prettierrc",
          "destination": "./",
          "conditions": [
            { "question_id": "features", "ans": { "regex": "Formatting" } }
          ]
        }
      ]
    }
  ]
}
```

### Pattern 4: Framework-Specific Configuration

**Use Case**: Different actions based on framework choice

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
      "question_id": "project_name",
      "question": "Enter project name:",
      "input_type": "input"
    },
    {
      "actions": [
        {
          "type": "execute",
          "command": "npx create-react-app [[[ANS:project_name]]]",
          "conditions": [{ "question_id": "framework", "ans": "React" }]
        },
        {
          "type": "execute",
          "command": "npm create vue@latest [[[ANS:project_name]]]",
          "conditions": [{ "question_id": "framework", "ans": "Vue" }]
        },
        {
          "type": "execute",
          "command": "npx @angular/cli new [[[ANS:project_name]]]",
          "conditions": [{ "question_id": "framework", "ans": "Angular" }]
        }
      ]
    }
  ]
}
```

### Pattern 5: Sequential Dependent Questions

**Use Case**: Questions that depend on previous answers

```json
{
  "steps": [
    {
      "question_id": "create_project",
      "question": "Do you want to create a new project?",
      "input_type": "select",
      "options": ["Yes", "No"]
    },
    {
      "question_id": "project_name",
      "question": "Enter project name:",
      "input_type": "input",
      "actions": []
    },
    {
      "actions": [
        {
          "type": "mkdir",
          "path": "./[[[ANS:project_name]]]",
          "conditions": [{ "question_id": "create_project", "ans": "Yes" }]
        }
      ]
    }
  ]
}
```

**Note**: Even if a step only asks a question, it can have an empty `actions` array.

### Pattern 6: Validation and Confirmation

**Use Case**: Confirm user input before proceeding

```json
{
  "steps": [
    {
      "question_id": "project_name",
      "question": "Enter project name:",
      "input_type": "input"
    },
    {
      "question_id": "confirm",
      "question": "Create project '[[[ANS:project_name]]]'? (yes/no)",
      "input_type": "input"
    },
    {
      "actions": [
        {
          "type": "mkdir",
          "path": "./[[[ANS:project_name]]]",
          "conditions": [
            { "question_id": "confirm", "ans": { "regex": "^yes$" } }
          ]
        },
        {
          "type": "execute",
          "command": "Write-Host 'Project creation cancelled.' -ForegroundColor Yellow",
          "conditions": [
            { "question_id": "confirm", "ans": { "regex": "^no$" } }
          ]
        }
      ]
    }
  ]
}
```

### Pattern 7: UUID Generation for Config Files

**Use Case**: Generate unique IDs for configuration

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
          "source": "./template/config.json",
          "destination": "./config.json"
        },
        {
          "type": "replace",
          "files": ["./config.json"],
          "target": "\"app_id\": \"\"",
          "value": "\"app_id\": \"[[[UUIDv4]]]\""
        },
        {
          "type": "replace",
          "files": ["./config.json"],
          "target": "\"app_name\": \"\"",
          "value": "\"app_name\": \"[[[ANS:app_name]]]\""
        }
      ]
    }
  ]
}
```

### Pattern 8: Action-Only Steps

**Use Case**: Execute actions without asking questions

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
          "command": "Write-Host 'Setting up project structure...'"
        },
        {
          "type": "mkdir",
          "path": "./[[[ANS:project_name]]]/src"
        },
        {
          "type": "mkdir",
          "path": "./[[[ANS:project_name]]]/tests"
        },
        {
          "type": "mkdir",
          "path": "./[[[ANS:project_name]]]/docs"
        }
      ]
    },
    {
      "actions": [
        {
          "type": "execute",
          "command": "Write-Host 'Project structure created!' -ForegroundColor Green"
        }
      ]
    }
  ]
}
```

---

## Advanced Techniques

### Using Regex for Name Validation

```json
{
  "question_id": "package_name",
  "question": "Enter npm package name (lowercase, no spaces):",
  "input_type": "input",
  "actions": [
    {
      "type": "execute",
      "command": "Write-Host 'Valid package name!' -ForegroundColor Green",
      "conditions": [
        { "question_id": "package_name", "ans": { "regex": "^[a-z0-9-]+$" } }
      ]
    },
    {
      "type": "execute",
      "command": "Write-Host 'Invalid package name!' -ForegroundColor Red",
      "conditions": [
        {
          "question_id": "package_name",
          "ans": { "regex": "^(?![a-z0-9-]+$)" }
        }
      ]
    }
  ]
}
```

### Multiple Conditions (AND Logic)

```json
{
  "type": "execute",
  "command": "npm install react-router-dom",
  "conditions": [
    { "question_id": "framework", "ans": "React" },
    { "question_id": "use_routing", "ans": "Yes" }
  ]
}
```

All conditions must be met for the action to execute.

### Array Matching (OR Logic)

```json
{
  "type": "copy",
  "source": "./template/frontend-config",
  "destination": "./",
  "conditions": [
    { "question_id": "framework", "ans": ["React", "Vue", "Angular"] }
  ]
}
```

Action executes if framework is any of the listed values.

### Cross-Referencing Answers

```json
{
  "steps": [
    {
      "question_id": "env",
      "question": "Environment:",
      "input_type": "select",
      "options": ["development", "production"]
    },
    {
      "question_id": "confirm_env",
      "question": "Confirm environment (type '[[[ANS:env]]]'):",
      "input_type": "input"
    },
    {
      "actions": [
        {
          "type": "execute",
          "command": "Write-Host 'Environment confirmed!'",
          "conditions": [
            { "question_id": "confirm_env", "ans": "[[[ANS:env]]]" }
          ]
        }
      ]
    }
  ]
}
```

---

## Testing Workflows

### 1. Start with Minimal Example

```json
{
  "steps": [
    {
      "question_id": "name",
      "question": "Enter name:",
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

### 2. Add One Feature at a Time

Test each addition:

- Add a new question
- Add a condition
- Add a file operation
- Add placeholder usage

### 3. Use Test Configuration File

Create `test-workflow.json`:

```json
{
  "steps": [
    {
      "question_id": "test",
      "question": "Test input:",
      "actions": [{ "type": "mkdir", "path": "./test_[[[ANS:test]]]" }]
    }
  ]
}
```

Run with:

```powershell
.\generator.ps1 -StepPath "test-workflow.json"
```

### 4. Test Edge Cases

- Empty inputs
- Special characters in names
- Very long inputs
- Paths with spaces
- Multiple conditions
- Missing template files

---

## Performance Considerations

### Minimize File Operations

❌ **Inefficient:**

```json
{
  "actions": [
    {
      "type": "replace",
      "files": ["./project/**/*.txt"],
      "target": "A",
      "value": "1"
    },
    {
      "type": "replace",
      "files": ["./project/**/*.txt"],
      "target": "B",
      "value": "2"
    },
    {
      "type": "replace",
      "files": ["./project/**/*.txt"],
      "target": "C",
      "value": "3"
    }
  ]
}
```

✅ **Better:** Use template with placeholders, copy once, replace all:

```json
{
  "actions": [
    { "type": "copy", "source": "./template", "destination": "./project/" },
    {
      "type": "replace",
      "files": ["./project/**/*.txt"],
      "target": ["[[[A]]]", "[[[B]]]", "[[[C]]]"],
      "value": "[[[ANS:mapping]]]" // Replace all in one pass
    }
  ]
}
```

### Use Exclude Patterns

```json
{
  "type": "replace",
  "files": {
    "include": ["./project/**/*.js"],
    "exclude": ["**/node_modules/**", "**/.git/**", "**/dist/**"]
  },
  "target": "OLD",
  "value": "NEW"
}
```

This prevents unnecessary file scanning in large directories.

---

## Common Mistakes

### 1. Condition on Non-Existent Question

❌ **Wrong:**

```json
{
  "actions": [
    {
      "type": "execute",
      "command": "echo 'test'",
      "conditions": [{ "question_id": "does_not_exist", "ans": "Yes" }]
    }
  ]
}
```

**Result**: Condition always fails silently.

### 2. Wrong Multiselect Condition

❌ **Wrong:**

```json
{
  "question_id": "features",
  "input_type": "multiselect",
  "options": ["A", "B", "C"],
  "actions": [
    {
      "type": "execute",
      "command": "echo A",
      "conditions": [{ "question_id": "features", "ans": "A" }]
    }
  ]
}
```

✅ **Correct:**

```json
{
  "conditions": [{ "question_id": "features", "ans": { "regex": "\\bA\\b" } }]
}
```

Use regex with word boundary `\\b` to match exact feature name.

### 3. Forgotten Placeholder in Condition

❌ **Wrong:**

```json
{
  "question_id": "path",
  "question": "Enter path:",
  "actions": [
    {
      "type": "copy",
      "source": "./template",
      "destination": "./[[[ANS:path]]]", // Placeholder here
      "conditions": [{ "question_id": "path", "ans": { "regex": "^.+$" } }] // But not here
    }
  ]
}
```

This is usually correct - conditions check the raw answer value, not the processed placeholder.

---

## Best Practices Summary

1. ✅ Order questions logically
2. ✅ Use descriptive IDs and clear question text
3. ✅ Group related actions together
4. ✅ Use multiselect instead of multiple yes/no questions
5. ✅ Test incrementally
6. ✅ Use placeholders extensively
7. ✅ Add exclude patterns for replace operations
8. ✅ Validate user input with conditions
9. ✅ Provide feedback with execute actions
10. ✅ Keep workflows simple and maintainable

---

## Related Skills

- [Understanding steps.json](../understanding-steps-json/SKILL.md) - Learn the JSON schema
- [Working with Placeholders](../working-with-placeholders/SKILL.md) - Master placeholders
- [Debugging and Testing](../debugging-and-testing/SKILL.md) - Test and debug workflows
