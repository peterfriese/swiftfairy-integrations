# SwiftFairy Plugin for Google Antigravity (Agent Manager & CLI)

This bundle provides a complete, drop-in plugin for **Google Antigravity** (CLI `agy` and the Antigravity Agent Manager).

## 📁 Bundle Contents

* **`plugin.json`**: Antigravity plugin manifest defining the `swiftfairy` plugin metadata and capabilities.
* **`mcp_config.json`**: MCP configuration mapping `swiftfairy` to the `swiftfairy-stdio` bridge binary.
* **`hooks/`**:
  * `hooks.json`: Lifecycle hook definitions attaching to the `PreToolUse` phase (`mcp_swiftfairy_.*audit.*`).
  * `hydrate-swiftfairy-source.js`: Private source hydration script that extracts active Swift editor buffers into arguments without relaying source unnecessarily through the LLM context window.
* **`skills/swiftfairy/SKILL.md`**: Specialized agent skill teaching Antigravity subagents how and when to invoke SwiftFairy audit commands, suppress rules, and interpret results.

## 🛠️ Installation Paths

* Target Plugin Directory: `~/.gemini/antigravity/plugins/swiftfairy/`

## 🚀 Quick Setup

### Using the Standalone Installer
```bash
./swiftfairy-standin install antigravity
```

### Manual Installation
1. Create the destination directory:
   ```bash
   mkdir -p ~/.gemini/antigravity/plugins/swiftfairy
   ```
2. Copy all files from `bundles/AntigravityPlugin/` into `~/.gemini/antigravity/plugins/swiftfairy/`.
3. In `mcp_config.json`, replace `__SWIFTFAIRY_STDIO_HELPER__` with:
   `/Applications/SwiftFairy.app/Contents/Helpers/swiftfairy-stdio`
4. Antigravity discovers this plugin automatically at launch. Verify using:
   ```bash
   agy plugin list
   ```
