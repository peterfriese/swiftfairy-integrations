# SwiftFairy Integration for Antigravity IDE

This bundle configures SwiftFairy for use inside **Antigravity IDE** (the desktop IDE for Google Antigravity).

## 📁 Bundle Contents

* **`mcp.json`**: MCP server definition registering `swiftfairy` under the IDE's Model Context Protocol manager.

## 🛠️ Installation Paths

* Configuration: `~/Library/Application Support/Antigravity IDE/User/mcp.json`

## 🚀 Quick Setup

### Using the Standalone Installer
```bash
./swiftfairy-standin install antigravity-ide
```

### Manual Installation
1. Merge the `swiftfairy` server configuration from `mcp.json` into:
   ```
   ~/Library/Application Support/Antigravity IDE/User/mcp.json
   ```
2. Replace `__SWIFTFAIRY_STDIO_HELPER__` with the absolute path to your `swiftfairy-stdio` helper:
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
3. Restart or reload Antigravity IDE. The SwiftFairy tools (`swiftfairy.audit_code`, `swiftfairy.find_guidance`, etc.) will appear in the MCP server registry.
