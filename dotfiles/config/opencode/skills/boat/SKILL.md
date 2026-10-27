---
name: "boat"
description: "Manage, execute commands, start/stop, or prompt agents in user's Boat cloud sandboxes (The Reference Edit: bx_4qhc25xp, Portrait Issue 02: bx_wbqyt3bf). Use whenever Boat, cloud sandboxes, or remote execution on these projects is requested."
---

# Boat Sandboxes Skill

Enables seamless control and remote execution in the user's persistent Boat cloud sandboxes (`boat.dev`).

## Configured Sandboxes

| Name | Sandbox ID | Subdomain | Project |
| :--- | :--- | :--- | :--- |
| **The Reference Edit** | `bx_4qhc25xp` | `box-node-959a352dcd18ce3a` | Visual research & reference magazine |
| **Portrait Issue 02** | `bx_wbqyt3bf` | `box-node-85bf2a71651db7f8` | Editorial magazine reader |

---

## Commands & Workflows

### 1. Check Status
```bash
boat list --all
# or using helper:
boat-box status
```

### 2. Resume / Start Sandbox (if stopped)
Sandboxes automatically suspend when idle to save billing. Start before running long workloads:
```bash
boat resume bx_4qhc25xp   # The Reference Edit
boat resume bx_wbqyt3bf   # Portrait Issue 02
```

### 3. Run Commands Directly (HTTP API - No SSH key needed)
```bash
boat exec bx_4qhc25xp "npm run build"
boat exec bx_wbqyt3bf "git status"
```

### 4. Send Coding Agent Prompts to Sandbox
Directly dispatch coding agent turns inside the cloud sandbox:
```bash
boat prompt bx_4qhc25xp --provider opencode "<prompt>"
boat prompt bx_wbqyt3bf --provider opencode "<prompt>"
```

### 5. Port Forwarding (Preview Dev Servers)
```bash
boat forward bx_4qhc25xp --remote 3000 --local 3000
```

### 6. Stop Sandbox (Cost Savings)
Stop the sandbox when tasks are finished:
```bash
boat stop bx_4qhc25xp
boat stop bx_wbqyt3bf
```
