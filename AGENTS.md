# AGENTS.md - Developer Guide for AI Agents

## Project Overview

### Purpose

This is an **interactive project setup automation tool** that executes predefined steps from a JSON configuration file (`steps.json`). The system asks users questions, processes their answers, and performs various file operations and command executions based on conditional logic.

**Key Features:**

- JSON-driven workflow execution
- Interactive user input (text input, single/multiple selection)
- Conditional action execution based on user answers
- File operations (copy, replace, symlink, mkdir)
- PowerShell command execution
- Extensible hook system for custom input types and actions
- Placeholder system for answer references and UUID generation

**Typical Use Cases:**

- Project template initialization
- Framework-specific configuration generation
- Development environment setup automation
- Plugin/addon initialization workflows

---

## Architecture

### Core Components

```
generator.ps1          # Main entry point - orchestrates the workflow
steps.json            # Configuration file defining the workflow
hooks/                # Hook scripts directory
  ├── common.ps1      # Shared utilities (Invoke-Replacement function)
  ├── input.ps1       # Input type: text input
  ├── select.ps1      # Input type: single selection
  ├── multiselect.ps1 # Input type: multiple selection
  ├── execute.ps1     # Action: execute PowerShell commands
  ├── replace.ps1     # Action: string replacement in files
  ├── copy.ps1        # Action: copy files/folders
  ├── symlink.ps1     # Action: create symbolic links
  └── mkdir.ps1       # Action: create directories
template/             # Optional template files directory
```

### Execution Flow

1. **Load Configuration**: `generator.ps1` loads and parses `steps.json`
2. **Process Steps Sequentially**: Each step is processed in order
3. **Ask Question**: If `question_id` exists, load the appropriate input hook and get user input
4. **Store Answer**: Save the answer in `$answers` hashtable
5. **Execute Actions**: For each action in the step:
   - Check conditions (if any)
   - Load the appropriate action hook
   - Execute the action with placeholder replacement
6. **Complete**: Display success message when all steps finish

---

## Agent Skills

This project provides specialized skills for AI agents to work effectively with the system. Each skill is documented in detail in the `.github/skills/` directory:

### Core Skills

1. **[Understanding steps.json](.github/skills/understanding-steps-json/SKILL.md)**
   - Learn the structure and schema of steps.json
   - Understand step properties, input types, and action types
   - Master conditional execution and file patterns

2. **[Creating Workflows](.github/skills/creating-workflows/SKILL.md)**
   - Design effective workflow patterns
   - Implement common use cases
   - Use conditional branching and multi-step processes

3. **[Working with Placeholders](.github/skills/working-with-placeholders/SKILL.md)**
   - Use answer references and UUID generation
   - Master escaping and placeholder processing
   - Add custom placeholders to the system

### Extension Skills

4. **[Extending Input Types](.github/skills/extending-input-types/SKILL.md)**
   - Create custom input type hooks
   - Implement Get-UserInput functions
   - Follow naming and interface conventions

5. **[Extending Action Types](.github/skills/extending-action-types/SKILL.md)**
   - Create custom action type hooks
   - Implement Invoke-\*Action functions
   - Handle paths, errors, and user feedback

### Development Skills

6. **[Coding Best Practices](.github/skills/coding-best-practices/SKILL.md)**
   - Follow naming conventions and code style
   - Handle paths, errors, and file operations
   - Use proper output formatting and colors

7. **[Debugging and Testing](.github/skills/debugging-and-testing/SKILL.md)**
   - Test custom hooks and workflows
   - Debug common issues
   - Troubleshoot hook loading and placeholder problems

---

## Quick Start for AI Agents

When working with this project:

1. **Read this file** to understand the overall architecture
2. **Review relevant skills** based on your task
3. **Check existing examples** in `steps.json` and `hooks/`
4. **Test your changes** using test configuration files
5. **Follow conventions** strictly to maintain consistency

**Key Principles:**

- Do NOT modify `generator.ps1` unless fixing core bugs
- Do NOT modify existing hooks unless fixing bugs - create new ones instead
- Always use `Invoke-Replacement` for placeholder processing
- Always source `hooks/common.ps1` in hook files
- Test thoroughly before committing changes

---

## File Structure

```
project/
├── generator.ps1                 # Main script (DO NOT MODIFY)
├── steps.json                    # Configuration file
├── README.md                     # User documentation
├── AGENTS.md                     # This file
├── .github/
│   └── skills/                   # Agent skills documentation
│       ├── understanding-steps-json/
│       ├── creating-workflows/
│       ├── working-with-placeholders/
│       ├── extending-input-types/
│       ├── extending-action-types/
│       ├── coding-best-practices/
│       └── debugging-and-testing/
├── hooks/
│   ├── common.ps1               # Shared utilities
│   ├── input.ps1                # Input type: text input
│   ├── select.ps1               # Input type: selection
│   ├── multiselect.ps1          # Input type: multiple selection
│   ├── execute.ps1              # Action: execute commands
│   ├── replace.ps1              # Action: replace in files
│   ├── copy.ps1                 # Action: copy files/folders
│   ├── symlink.ps1              # Action: create symlinks
│   └── mkdir.ps1                # Action: create directories
└── template/                     # Optional template directory
```

**For detailed information on specific tasks, refer to the appropriate skill documentation in `.github/skills/`.**
