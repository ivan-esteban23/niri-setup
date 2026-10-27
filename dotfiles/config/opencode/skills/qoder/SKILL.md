---
name: "qoder"
description: "Execute coding tasks, code refactoring, bug fixes, explanations, or codebase planning using Qoder CLI (qoder / qodercli). Use whenever Qoder or Alibaba Qoder CLI is requested."
---

# Qoder CLI Integration Skill

Executes agentic coding, review, and refactoring tasks using the local Qoder CLI installation (`~/.local/bin/qoder` / `qodercli`).

## Capabilities

- **Interactive Mode:** Run `qoder` or `qodercli` directly in a terminal for interactive coding sessions.
- **Headless / One-shot Execution:** Execute non-interactive queries and code generation via `-p/--print`:
  ```bash
  qodercli --dangerously-skip-permissions -p "<detailed instructions or prompt>"
  ```
- **Model Selection:** Specify models via `-m` (e.g. `-m auto`, `-m lite`, `-m performance`, etc.):
  ```bash
  qodercli -m auto -p "<task>"
  ```
- **Login / Authentication:**
  Authenticate once by running in a terminal:
  ```bash
  qoder login
  ```
