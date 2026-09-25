# SwiftFairy Integration Guide & Native Swift Architecture

This document provides Nil Coalescing Limited with the architectural blueprint and integration documentation for the drop-in [`SwiftFairyIntegrationInstaller.swift`](../SwiftFairyIntegrationInstaller.swift) source file, supporting:

* **Google Antigravity** (Agent Manager & CLI)
* **Antigravity IDE**
* **Gemini CLI** (with zero-hang Folder Trust pre-authorization)
* **OpenCode & OpenChamber**
* **Xcode 16 / 27 Coding Assistant** (with versioned Xcode fallback)
* **Cursor**
* **Visual Studio Code & VS Code Insiders**

---

## 🏗️ Architectural Overview

SwiftFairy originally relied on spawning external CLI subprocesses (`Process()`) to install extensions for tools like Gemini CLI. In headless macOS GUI environments, non-interactive subprocesses that prompt for authorization deadlock, leaving the app in an infinite "idling" state.

The improved architecture standardizes on **Declarative Direct Placement**:
1. **Zero Process Execution**: Extensions and plugins are copied directly into the agent's expected configuration directory (`~/.gemini/antigravity/plugins/`, `~/.gemini/extensions/`, `~/.cursor/plugins/local/`).
2. **Template Variable Substitution**: Bundled JSON configurations contain `__SWIFTFAIRY_STDIO_HELPER__`, which is substituted with the runtime path to `swiftfairy-stdio` during copy.
3. **Pre-Authorization of Security Stores**: Security stores (such as Gemini's `~/.gemini/trustedFolders.json`) are updated directly by SwiftFairy, preventing headless stdin blockages.
4. **Dynamic Environment Queries**: Where external tools are necessary (such as detecting versioned beta Xcode installations), SwiftFairy queries `/usr/bin/xcode-select -p` rather than checking hardcoded paths.

---

## 📦 Bundled Resources Structure

Include the bundle folders from `swiftfairy-integrations/bundles/` directly inside `SwiftFairy.app/Contents/Resources/`:

```text
SwiftFairy.app/Contents/Resources/
├── AntigravityPlugin/
│   ├── plugin.json
│   ├── mcp_config.json
│   ├── hooks/
│   │   ├── hooks.json
│   │   └── hydrate-swiftfairy-source.js
│   └── skills/swiftfairy/SKILL.md
├── AntigravityIDE/
│   └── mcp.json
├── Cursor/
│   ├── plugin.json
│   ├── mcp.json
│   └── skills/swiftfairy/SKILL.md
├── GeminiCLI/
│   ├── gemini-extension.json
│   ├── GEMINI.md
│   ├── .gemini-extension-install.json
│   ├── hooks/
│   │   ├── hooks.json
│   │   └── hydrate-swiftfairy-source.js
│   └── skills/swiftfairy/SKILL.md
├── OpenCode/
│   ├── opencode.jsonc
│   └── skills/swiftfairy/SKILL.md
├── VSCode/
│   ├── mcp.json
│   └── settings.json
└── Xcode/
    └── mcp-servers.json
```

---

## 💻 Swift Integration Implementation

Nil Coalescing can add [`SwiftFairyIntegrationInstaller.swift`](../SwiftFairyIntegrationInstaller.swift) directly into the app's target.

### Example UI / ViewModel Usage:

```swift
import SwiftUI

@Observable
final class IntegrationsViewModel {
    private let installer = SwiftFairyIntegrationInstaller.shared
    var statuses: [SwiftFairyAgent: IntegrationStatus] = [:]
    var isInstalling = false
    var errorMessage: String?

    func refresh() {
        statuses = installer.checkAllStatuses()
    }

    func install(agent: SwiftFairyAgent) {
        guard let helperURL = installer.defaultStdioHelperURL else {
            errorMessage = "swiftfairy-stdio helper binary not found."
            return
        }

        isInstalling = true
        defer { isInstalling = false }

        do {
            switch agent {
            case .antigravity:
                try installer.installAntigravityPlugin(stdioHelperPath: helperURL.path)
            case .antigravityIDE:
                try installer.installAntigravityIDE(stdioHelperPath: helperURL.path)
            case .geminiCLI:
                try installer.installGeminiExtensionDirectly(stdioHelperPath: helperURL.path)
            case .openCode:
                try installer.installOpenCodeIntegration(stdioHelperPath: helperURL.path)
            case .xcode:
                try installer.installXcodeIntegration(stdioHelperPath: helperURL.path)
            case .cursor:
                try installer.installCursorPlugin(stdioHelperPath: helperURL.path)
            case .vscode:
                try installer.installVSCodeIntegration(stdioHelperPath: helperURL.path)
            }
            refresh()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func uninstall(agent: SwiftFairyAgent) {
        do {
            switch agent {
            case .antigravity:
                try installer.uninstallAntigravityPlugin()
            case .antigravityIDE:
                try installer.uninstallAntigravityIDE()
            case .geminiCLI:
                try installer.uninstallGeminiExtensionDirectly()
            case .openCode:
                try installer.uninstallOpenCodeIntegration()
            case .xcode:
                try installer.uninstallXcodeIntegration()
            case .cursor:
                try installer.uninstallCursorPlugin()
            case .vscode:
                try installer.uninstallVSCodeIntegration()
            }
            refresh()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
```

---

## 🔍 Detailed Agent Integration Mechanisms

### 1. Google Antigravity (Agent Manager & CLI)
* **Target**: `~/.gemini/antigravity/plugins/swiftfairy/`
* **Mechanism**: Antigravity automatically indexes plugins located in this directory at startup.
* **Special Features**: Includes `PreToolUse` hook (`hydrate-swiftfairy-source.js`) to transfer active editor Swift code directly into tool invocation arguments without context-window pollution.

### 2. Antigravity IDE
* **Target**: `~/Library/Application Support/Antigravity IDE/User/mcp.json`
* **Mechanism**: Safely loads and merges the `swiftfairy` key under `mcpServers`.

### 3. Gemini CLI
* **Target**: `~/.gemini/extensions/swiftfairy/` & `~/.gemini/trustedFolders.json`
* **Mechanism**: Direct copy with `.gemini-extension-install.json` and pre-authorized folder trust in `trustedFolders.json` (`"TRUST_FOLDER"`).
* **Fix**: Completely eliminates the interactive TTY stdin prompt (`Do you want to trust this folder? [y/N]`) that caused SwiftFairy's UI to freeze.

### 4. OpenCode & OpenChamber
* **Target**: `~/.config/opencode/opencode.jsonc` & `~/.config/opencode/skills/swiftfairy/SKILL.md`
* **Mechanism**: Safely strips JSONC comments, merges `mcp.swiftfairy`, and deploys the agent skill.

### 5. Xcode CodingAssistant
* **Target**: `~/Library/Developer/Xcode/CodingAssistant/mcp-servers.json`
* **Mechanism**: Writes the stdio helper to Xcode's MCP registry. Detection falls back to `/usr/bin/xcode-select -p` to support multiple beta installations (e.g. from Xcodes.app).

### 6. Cursor & Visual Studio Code
* **Cursor Target**: `~/.cursor/plugins/local/swiftfairy/`
* **VS Code Target**: `~/Library/Application Support/Code/User/mcp.json`
