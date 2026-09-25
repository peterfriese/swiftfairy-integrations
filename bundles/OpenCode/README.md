# SwiftFairy Integration for OpenCode & OpenChamber

This bundle provides full, end-to-end integration of SwiftFairy with **OpenCode** and **OpenChamber**.

## 📁 Bundle Contents

* **`opencode.jsonc`**: Production configuration file registering the `swiftfairy` MCP server with OpenCode's execution runner.
* **`skills/swiftfairy/SKILL.md`**: Specialized skill instructing OpenCode agents on how to leverage SwiftFairy audit tools, context-retrieval conventions, and guidance rules.

## 🛠️ Installation Paths

* Configuration: `~/.config/opencode/opencode.jsonc` (or `~/.config/openchamber/opencode.jsonc`)
* Skill: `~/.config/opencode/skills/swiftfairy/SKILL.md`

## 🚀 Quick Setup

### Using the Standalone Installer
```bash
./swiftfairy-standin install opencode
```

### Manual Installation
1. Ensure the directory exists:
   ```bash
   mkdir -p ~/.config/opencode/skills/swiftfairy
   ```
2. Copy `skills/swiftfairy/SKILL.md` to `~/.config/opencode/skills/swiftfairy/SKILL.md`.
3. Merge or copy `opencode.jsonc` into `~/.config/opencode/opencode.jsonc`, replacing `__SWIFTFAIRY_STDIO_HELPER__` with your local helper path (e.g. `/Applications/SwiftFairy.app/Contents/Helpers/swiftfairy-stdio`).
