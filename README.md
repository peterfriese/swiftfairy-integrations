# SwiftFairy Integrations

This repository contains pre-packaged integration bundles and a standalone setup tool to connect **SwiftFairy** with modern AI coding agents:

* **Google Antigravity (Agent Manager & CLI)**
* **Antigravity IDE**
* **OpenCode & OpenChamber**
* **Xcode Coding Assistant**
* **Cursor & Visual Studio Code**

---

## 📦 What's Inside

```text
swiftfairy-integrations/
├── swiftfairy-standin          # Standalone CLI tool to install/test/uninstall
├── bundles/
│   ├── AntigravityPlugin/      # Complete bundle for Antigravity Agent Manager
│   │   ├── plugin.json         # Plugin manifest
│   │   ├── mcp_config.json     # MCP server configuration
│   │   ├── hooks/              # Private source transfer hook
│   │   │   ├── hooks.json
│   │   │   └── hydrate-swiftfairy-source.js
│   │   └── skills/             # Standard SwiftFairy reference skill
│   │       └── swiftfairy/
│   │           └── SKILL.md
│   ├── AntigravityIDE/         # Profile config for Antigravity IDE
│   │   └── mcp.json
│   ├── OpenCode/               # MCP snippet & skill for OpenCode & OpenChamber
│   │   ├── mcp_snippet.jsonc
│   │   └── skills/swiftfairy/SKILL.md
│   └── Xcode/                  # Xcode 16/27 CodingAssistant configuration
│       └── mcp-servers.json
└── docs/
    └── swift-integration-patch.md  # Swift code blueprint for SwiftFairy.app
```

---

## 🚀 Using the `swiftfairy-standin` CLI

You can use the standalone script directly to manage integrations on your machine:

```bash
# Check status across all detected coding agents
./swiftfairy-standin list

# Install an integration
./swiftfairy-standin install antigravity
./swiftfairy-standin install opencode
./swiftfairy-standin install xcode
./swiftfairy-standin install all

# Uninstall an integration
./swiftfairy-standin uninstall antigravity
./swiftfairy-standin uninstall all

# Verify the stdio helper binary
./swiftfairy-standin test
```

---

## 👩‍💻 Notes for Nil Coalescing / Natalia

To integrate these directly into the SwiftFairy macOS app:
1. Copy `bundles/AntigravityPlugin` into `SwiftFairy.app/Contents/Resources/`.
2. See [`docs/swift-integration-patch.md`](./docs/swift-integration-patch.md) for the Swift code to add to `SwiftFairyIntegrationInstaller`:
   * Direct file installation into `~/.gemini/antigravity/plugins/swiftfairy/` (avoids hanging on interactive CLI prompts).
   * One-line addition to scan `Antigravity IDE/User/mcp.json`.
   * OpenCode `opencode.jsonc` merge.
   * `xcode-select -p` fallback for versioned Xcode installations.
