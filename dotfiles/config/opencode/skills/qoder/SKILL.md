---
name: "qoder"
description: "Execute coding tasks, PR review, code refactoring, bug fixes, or codebase planning using Qoder CLI (qoder / qodercli) with specific models like Qwen 3.8 Flash Extra High or DeepSeek Flash High."
---

# Qoder CLI Integration Skill

Executes agentic coding, PR review, and refactoring tasks using the local Qoder CLI installation (`~/.local/bin/qoder` / `qodercli`).

## Model & Reasoning Presets

When the user asks for specific models or reasoning effort, map them directly to these flags:

1. **Qwen 3.8 Flash Extra High (Default for deep reasoning & PR review):**
   ```bash
   qodercli -m Qwen3.8-Flash --reasoning-effort xhigh --dangerously-skip-permissions -p "<prompt>"
   ```

2. **DeepSeek Flash High (Fast, high-quality code generation & analysis):**
   ```bash
   qodercli -m DeepSeek-Flash --reasoning-effort high --dangerously-skip-permissions -p "<prompt>"
   ```

3. **Standard / Auto:**
   ```bash
   qodercli -m auto --dangerously-skip-permissions -p "<prompt>"
   ```

## PR Review Execution Pattern

When asked to review a PR or git changes:
1. Obtain the diff or PR status: `git diff HEAD~1` or `git status`.
2. Pass the diff or file context into `qodercli -p`:
   ```bash
   qodercli -m Qwen3.8-Flash --reasoning-effort xhigh --dangerously-skip-permissions -p "Review this git diff and check for edge cases, performance issues, and bugs: $(git diff HEAD~1)"
   ```
