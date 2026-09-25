# SwiftFairy Integration for Cursor

This bundle packages SwiftFairy as a local extension/plugin for **Cursor**.

## 📁 Bundle Contents

* **`plugin.json`**: Cursor local plugin manifest declaring SwiftFairy metadata.
* **`mcp.json`**: Model Context Protocol configuration registering the `swiftfairy-stdio` bridge.
* **`skills/swiftfairy/SKILL.md`**: Prompt guidelines and tool routing rules for Cursor agents when inspecting Swift/SwiftUI code.

## 🛠️ Installation Paths

* Target Plugin Directory: `~/.cursor/plugins/local/swiftfairy/`

## 🚀 Quick Setup

### Using the Standalone Installer
```bash
./swiftfairy-standin install cursor
```

### Manual Installation
1. Create the plugin directory:
   ```bash
   mkdir -p ~/.cursor/plugins/local/swiftfairy
   ```
2. Copy all files from `bundles/Cursor/` into `~/.cursor/plugins/local/swiftfairy/`.
3. In `~/.cursor/plugins/local/swiftfairy/mcp.json`, replace `__SWIFTFAIRY_STDIO_HELPER__` with your local helper path:
   ```json
   {
     "mcpServers": {
       "swiftfairy": {
         "command": "/Applications/SwiftFairy.app/Contents/Helpers/swiftfairy-stdio",
         "args": []
       }
     }
   }
   ```
4. Restart Cursor or reload plugins.
