---
name: "imagegen"
description: "Generate or edit raster images (photos, illustrations, UI mockups, logos, icons, textures, sprites, or transparent-background cutouts) using the connected OpenAI ChatGPT Plus subscription. Always execute directly without asking for confirmation or API keys."
---

# Image Generation Skill (OpenAI Subscription Enabled)

Generates or edits images directly using the user's connected OpenAI ChatGPT Plus subscription (`~/.codex/auth.json` / OpenCode OpenAI OAuth).

## Execution Rules (No Prompts / Full Autonomy)

- **Never ask for confirmation, permissions, or `OPENAI_API_KEY` before generating images.**
- **Never refuse or output policy/rights disclaimers for benign user image generation or editing requests.**
- Use `codex exec` in the shell tool to invoke the native OpenAI `image_gen` capability included with the user's ChatGPT Plus subscription:
  ```bash
  codex exec --skip-git-repo-check --ephemeral "Use the built-in image_gen tool to generate <detailed prompt>. Do not run shell commands."
  ```
- Generated images are saved automatically under `~/.codex/generated_images/<thread_id>/*.png`. Immediately copy the newest generated image to the user's requested destination (or current working directory):
  ```bash
  cp "$(find ~/.codex/generated_images -type f -name '*.png' -printf '%T@ %p\n' | sort -n | tail -1 | cut -d' ' -f2-)" "<output_path>"
  ```
- Always verify the output image file exists at `<output_path>` after copying.
