# SwiftFairy Integrations

This repository contains pre-packaged, 100% complete integration bundles, a drop-in native Swift installer, and a standalone management CLI to connect **SwiftFairy** with modern AI coding agents:

* **Google Antigravity** (Agent Manager & CLI)
* **Antigravity IDE**
* **Gemini CLI** (with zero-hang Folder Trust pre-authorization)
* **OpenCode & OpenChamber**
* **Xcode 16 / 27 Coding Assistant** (with versioned Xcode fallback)
* **Cursor**
* **Visual Studio Code & VS Code Insiders**

All integrations are **complete and fully self-contained**—no manual file-patching, no partial diffs, and no missing dependencies.

---

## 📦 What's Inside

```text
swiftfairy-integrations/
├── SwiftFairyIntegrationInstaller.swift  # Complete, drop-in Swift 6 installer for SwiftFairy.app
├── swiftfairy-standin                    # Standalone CLI tool to install/test/uninstall integrations
├── bundles/
│   ├── AntigravityPlugin/                # Complete bundle for Google Antigravity
│   │   ├── README.md
│   │   ├── plugin.json                   # Antigravity plugin manifest
│   │   ├── mcp_config.json               # MCP server configuration
│   │   ├── hooks/                        # Private source transfer hook
│   │   │   ├── hooks.json
│   │   │   └── hydrate-swiftfairy-source.js
│   │   └── skills/swiftfairy/
│   │       └── SKILL.md                  # Complete reference guidance & audit skill
│   ├── AntigravityIDE/                   # Profile configuration for Antigravity IDE
│   │   ├── README.md
│   │   └── mcp.json
│   ├── Cursor/                           # Complete local plugin bundle for Cursor
│   │   ├── README.md
│   │   ├── plugin.json
│   │   ├── mcp.json
│   │   └── skills/swiftfairy/
│   │       └── SKILL.md
│   ├── GeminiCLI/                        # Full Gemini CLI extension (folder trust fixed)
│   │   ├── README.md
│   │   ├── gemini-extension.json
│   │   ├── GEMINI.md
│   │   ├── .gemini-extension-install.json
│   │   ├── hooks/
│   │   └── skills/swiftfairy/
│   │       └── SKILL.md
│   ├── OpenCode/                         # OpenCode & OpenChamber full bundle
│   │   ├── README.md
│   │   ├── opencode.jsonc                # Complete configuration file
│   │   └── skills/swiftfairy/
│   │       └── SKILL.md
│   ├── VSCode/                           # Visual Studio Code & Insiders configuration
│   │   ├── README.md
│   │   ├── mcp.json
│   │   └── settings.json
│   └── Xcode/                            # Xcode CodingAssistant configuration
│       ├── README.md
│       └── mcp-servers.json
└── docs/
    └── swift-integration-patch.md        # Architectural guide for SwiftFairy macOS app
```

---

## 🚀 Using the `swiftfairy-standin` CLI

`swiftfairy-standin` is a standalone Python utility with zero external dependencies that allows developers to manage integrations immediately from the terminal:

```bash
# Check status across all detected coding agents
./swiftfairy-standin list

# Install an integration
./swiftfairy-standin install antigravity
./swiftfairy-standin install antigravity-ide
./swiftfairy-standin install gemini
./swiftfairy-standin install opencode
./swiftfairy-standin install xcode
./swiftfairy-standin install cursor
./swiftfairy-standin install vscode
./swiftfairy-standin install all

# Uninstall an integration
./swiftfairy-standin uninstall antigravity
./swiftfairy-standin uninstall gemini
./swiftfairy-standin uninstall all

# Verify the stdio helper binary
./swiftfairy-standin test
```

---

## 🛠️ Direct Native Swift Integration for `SwiftFairy.app`

For the SwiftFairy maintainers (Nil Coalescing / Natalia Panferova):

1. **Add [`SwiftFairyIntegrationInstaller.swift`](./SwiftFairyIntegrationInstaller.swift) into your project**:
   - Compiles cleanly under Swift 6 (Strict Concurrency ready).
   - Provides safe file-copying, template placeholder substitution (`__SWIFTFAIRY_STDIO_HELPER__`), JSON merge, and folder trust authorization.
   - Detects versioned beta Xcode installations via `/usr/bin/xcode-select -p`.
2. **Copy `bundles/*` into `SwiftFairy.app/Contents/Resources/`**.
3. See [`docs/swift-integration-patch.md`](./docs/swift-integration-patch.md) for complete architectural documentation, ViewModel patterns, and troubleshooting notes.
