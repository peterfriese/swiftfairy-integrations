# SwiftFairy Integration for Xcode CodingAssistant

This bundle integrates SwiftFairy directly into Apple's **Xcode 16 / 27 Coding Assistant** via Model Context Protocol (MCP).

## 📁 Bundle Contents

* **`mcp-servers.json`**: MCP configuration file declaring the `swiftfairy-stdio` helper executable for Xcode's CodingAssistant daemon.

## 🛠️ Installation Paths

* Configuration: `~/Library/Developer/Xcode/CodingAssistant/mcp-servers.json`

## 🚀 Quick Setup

### Using the Standalone Installer
```bash
./swiftfairy-standin install xcode
```

### Manual Installation
1. Ensure the Xcode CodingAssistant folder exists:
   ```bash
   mkdir -p ~/Library/Developer/Xcode/CodingAssistant
   ```
2. Merge or copy `mcp-servers.json` into `~/Library/Developer/Xcode/CodingAssistant/mcp-servers.json`, replacing `__SWIFTFAIRY_STDIO_HELPER__` with:
   `/Applications/SwiftFairy.app/Contents/Helpers/swiftfairy-stdio`
3. If using custom Xcode installs via `Xcodes.app` or betas, verify the active developer directory:
   ```bash
   xcode-select -p
   ```
