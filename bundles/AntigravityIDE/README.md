# SwiftFairy Integration for Antigravity IDE

This bundle provides a complete, multi-tiered integration of SwiftFairy for **Antigravity IDE** (Google's AI-first integrated development environment built on the VS Code shell).

## 📁 Bundle Contents

* **`mcp.json`**: Model Context Protocol configuration registering `swiftfairy-stdio` with Antigravity IDE's MCP manager.
* **`settings.json`**: Recommended user settings enabling agent tooling and MCP server bindings.
* **`skills/swiftfairy/SKILL.md`**: Specialized Antigravity skill instructing the IDE agent on tool selection, guidance levels (`MUST`/`SHOULD`/`CONSIDER`), context requests, and rule suppression.
* **`rules/AGENTS.md`**: Contextual coding rules automatically ingested during Swift/SwiftUI editing sessions.

## 🛠️ Installation Locations

### 1. Global User Configuration (Recommended)
* **MCP Server**: `~/Library/Application Support/Antigravity IDE/User/mcp.json`
* **Agent Skill**: `~/.gemini/antigravity/skills/swiftfairy/SKILL.md` (or `~/.gemini/config/skills/swiftfairy/SKILL.md`)
* **Agent Rules**: `~/.gemini/config/AGENTS.md`

### 2. Workspace Configuration (Project-Specific)
Place inside your project root to share with your team:
* `.agents/skills/swiftfairy/SKILL.md`
* `.agents/rules/AGENTS.md`

## 🚀 Quick Setup

### Using the Standalone Installer
```bash
./swiftfairy-standin install antigravity-ide
```
This automatically:
1. Configures `mcp.json` in `~/Library/Application Support/Antigravity IDE/User/mcp.json`.
2. Installs the `swiftfairy` skill to `~/.gemini/antigravity/skills/swiftfairy/SKILL.md` so the IDE agent can immediately invoke SwiftFairy tools with full contextual intelligence.

### Manual Setup
1. Merge the `swiftfairy` entry from `mcp.json` into:
   `~/Library/Application Support/Antigravity IDE/User/mcp.json`
   replacing `__SWIFTFAIRY_STDIO_HELPER__` with your actual helper binary path.
2. Copy `skills/swiftfairy/` to `~/.gemini/antigravity/skills/swiftfairy/`.
3. Reload or restart Antigravity IDE.
