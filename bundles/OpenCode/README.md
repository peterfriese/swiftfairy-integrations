# SwiftFairy Integration for OpenCode v2 & OpenChamber

This bundle provides full, end-to-end integration of SwiftFairy with **OpenCode v2** (and OpenChamber).

## 📁 Bundle Contents

* **`opencode.jsonc`**: Production configuration file matching the official OpenCode v2 schema (`https://opencode.ai/config.json`), registering the `swiftfairy` MCP server with OpenCode's execution runner.
* **`skills/swiftfairy/SKILL.md`**: Specialized skill instructing OpenCode v2 agents on how to leverage SwiftFairy audit tools, context-retrieval conventions, and guidance rules.

## 🛠️ Installation Paths

* Configuration: `~/.config/opencode/opencode.jsonc` (or `~/.config/openchamber/opencode.jsonc`)
* Skill: `~/.config/opencode/skills/swiftfairy/SKILL.md`

## 🚀 Quick Setup

### Using the Standalone Installer
```bash
./swiftfairy-standin install opencode
```
This automatically updates your configuration, places the skill, and invokes `opencode reload` so the running OpenCode v2 daemon connects immediately.

### Verification in OpenCode v2
After installation, verify with:
```bash
opencode mcp list
```
Output:
```text
✓ swiftfairy  connected
```
You can then run queries or edits in OpenCode v2:
```bash
opencode run "Audit this Swift file using SwiftFairy"
```
The agent automatically detects the 6 tools from the `swiftfairy` MCP server (`swiftfairy_find_guidance`, `swiftfairy_audit_code`, `swiftfairy_audit_changes`, `swiftfairy_audit_batches`, `swiftfairy_open_app`, `swiftfairy_start_trials`).
