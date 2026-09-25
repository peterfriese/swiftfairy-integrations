# SwiftFairy Integration for Visual Studio Code

This bundle configures SwiftFairy for **Visual Studio Code** and **Visual Studio Code Insiders**.

## 📁 Bundle Contents

* **`mcp.json`**: MCP configuration for VS Code's MCP extension or native agent integration.
* **`settings.json`**: Alternative configuration block for VS Code user settings.

## 🛠️ Installation Paths

* Standard VS Code: `~/Library/Application Support/Code/User/mcp.json`
* VS Code Insiders: `~/Library/Application Support/Code - Insiders/User/mcp.json`

## 🚀 Quick Setup

### Using the Standalone Installer
```bash
./swiftfairy-standin install vscode
```

### Manual Installation
1. Ensure the user settings directory exists:
   ```bash
   mkdir -p "$HOME/Library/Application Support/Code/User"
   ```
2. Merge the configuration into `mcp.json`, substituting `__SWIFTFAIRY_STDIO_HELPER__` with your actual binary path:
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
