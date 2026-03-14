---
description: "Use when implementing MediaWriter flow changes, Bazzite branding/content updates, Windows build setup, or dependency cleanup. Enforces Bazzite-only UX, GUI-only user flow, and safe cleanup behavior."
name: "Bazzite Windows Flow Rules"
applyTo: "src/app/**"
---
# Bazzite Windows Flow Rules

- Treat this repo customization as Bazzite-first for active feature work.
- Keep startup flow focused on exactly three user actions:
  - Flash Bazzite to USB
  - Download Bazzite ISO only
  - Flash existing Bazzite ISO to USB
- Keep end-user UX GUI-only. Do not introduce terminal/console interactions in app flows.
- For download-only flow, require artifact selection then save-path picker and GUI download progress; do not route to USB device selection.
- Prioritize Windows implementation and validation before other platforms unless explicitly requested.
- Preserve user worktree safety:
  - Do not revert or alter git-tracked project changes during environment/dependency cleanup unless explicitly requested.
- When asked for guided setup, provide one clear next step at a time.
