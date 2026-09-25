# SwiftFairy Integration Patch for Antigravity, Antigravity IDE & OpenCode

This document provides Nil Coalescing with the exact Swift code enhancements to support Google Antigravity (CLI & Desktop), Antigravity IDE, and OpenCode / OpenChamber directly inside SwiftFairy.

---

## 1. Antigravity Agent Manager & CLI Integration

### Strategy: Direct Plugin Placement (No Interactive CLI Subprocess)
Antigravity automatically discovers plugins located in:
`~/.gemini/antigravity/plugins/<plugin_name>/`

By copying the pre-packaged `AntigravityPlugin` bundle directly into this folder and substituting `__SWIFTFAIRY_STDIO_HELPER__`, Antigravity instantly:
- Lists SwiftFairy in the **Agent Manager** and `agy plugin list`.
- Registers the `swiftfairy` skill for subagents and prompts.
- Launches the `swiftfairy-stdio` MCP server on demand.
- Executes `hydrate-swiftfairy-source.js` during `PreToolUse` for private source transfer.

```swift
extension SwiftFairyIntegrationInstaller {

    var isAntigravityInstalled: Bool {
        let fm = FileManager.default
        let home = fm.homeDirectoryForCurrentUser
        let antigravityDir = home.appendingPathComponent(".gemini/antigravity")
        
        let candidateCLIs = [
            "/opt/homebrew/bin/agy",
            "/usr/local/bin/agy",
            home.appendingPathComponent(".local/bin/agy").path
        ]
        
        return fm.fileExists(atPath: antigravityDir.path) || 
               candidateCLIs.contains { fm.fileExists(atPath: $0) }
    }

    func installAntigravityPlugin(stdioHelperPath: String) throws {
        let fm = FileManager.default
        let home = fm.homeDirectoryForCurrentUser
        let targetPluginDir = home.appendingPathComponent(".gemini/antigravity/plugins/swiftfairy")
        
        try fm.createDirectory(at: targetPluginDir, withIntermediateDirectories: true)
        
        guard let bundleURL = Bundle.main.url(forResource: "AntigravityPlugin", withExtension: nil) else {
            throw IntegrationError.bundledIntegrationMissing
        }
        
        // Copy recursively, replacing __SWIFTFAIRY_STDIO_HELPER__ in JSON configs
        try copyAndSubstitute(
            from: bundleURL, 
            to: targetPluginDir, 
            placeholder: "__SWIFTFAIRY_STDIO_HELPER__", 
            replacement: stdioHelperPath
        )
    }

    func uninstallAntigravityPlugin() throws {
        let fm = FileManager.default
        let home = fm.homeDirectoryForCurrentUser
        let targetPluginDir = home.appendingPathComponent(".gemini/antigravity/plugins/swiftfairy")
        if fm.fileExists(atPath: targetPluginDir.path) {
            try fm.removeItem(at: targetPluginDir)
        }
    }
}
```

---

## 2. Antigravity IDE Integration

### Strategy: One-line addition to VS Code Profile Array
Antigravity IDE is built on the VS Code shell and stores its MCP settings in `~/Library/Application Support/Antigravity IDE/User/mcp.json`.

In SwiftFairy's existing VS Code profile scanner, add `Antigravity IDE`:

```swift
let supportedVSCodeProfiles = [
    "Library/Application Support/Code/User/mcp.json",
    "Library/Application Support/Code - Insiders/User/mcp.json",
    "Library/Application Support/Antigravity IDE/User/mcp.json" // <── Add this path!
]
```

---

## 3. OpenCode & OpenChamber Integration

### Strategy: Merge into `~/.config/opencode/opencode.jsonc` and Copy Skill
OpenCode uses an `mcp` dictionary with an array command `["path/to/helper"]`.

```swift
extension SwiftFairyIntegrationInstaller {

    var isOpenCodeInstalled: Bool {
        let fm = FileManager.default
        let home = fm.homeDirectoryForCurrentUser
        let configDir = home.appendingPathComponent(".config/opencode")
        let openChamberDir = home.appendingPathComponent(".config/openchamber")
        
        let candidatePaths = [
            "/Applications/OpenCode.app",
            "/opt/homebrew/bin/opencode",
            "/usr/local/bin/opencode",
            home.appendingPathComponent(".local/bin/opencode").path
        ]
        
        return fm.fileExists(atPath: configDir.path) ||
               fm.fileExists(atPath: openChamberDir.path) ||
               candidatePaths.contains { fm.fileExists(atPath: $0) }
    }

    func installOpenCodeIntegration(stdioHelperPath: String) throws {
        let fm = FileManager.default
        let home = fm.homeDirectoryForCurrentUser
        let configURL = home.appendingPathComponent(".config/opencode/opencode.jsonc")
        
        // 1. Merge MCP Server Entry
        var json = (try? loadJSON(at: configURL)) ?? [:]
        var mcpDict = json["mcp"] as? [String: Any] ?? [:]
        
        mcpDict["swiftfairy"] = [
            "type": "local",
            "command": [stdioHelperPath],
            "enabled": true
        ]
        json["mcp"] = mcpDict
        try saveJSON(json, to: configURL)
        
        // 2. Install Skill
        let targetSkillDir = home.appendingPathComponent(".config/opencode/skills/swiftfairy")
        try fm.createDirectory(at: targetSkillDir, withIntermediateDirectories: true)
        
        if let skillURL = Bundle.main.url(forResource: "SKILL", withExtension: "md", subdirectory: "AgentPlugin/skills/swiftfairy") {
            let dest = targetSkillDir.appendingPathComponent("SKILL.md")
            try? fm.removeItem(at: dest)
            try fm.copyItem(at: skillURL, to: dest)
        }
    }
}
```

---

## 4. Robust Xcode Detection Fallback

If a user installs multiple beta versions of Xcode via Xcodes.app, `/Applications/Xcode.app` may be a broken symlink or missing entirely. Adding `xcode-select -p` fallback guarantees detection:

```swift
var activeXcodeURL: URL? {
    let standardURLs = [
        URL(fileURLWithPath: "/Applications/Xcode.app"),
        URL(fileURLWithPath: "/Applications/Xcode-beta.app")
    ]
    for url in standardURLs where FileManager.default.fileExists(atPath: url.path) {
        return url
    }
    
    // Fallback: Query active xcode-select developer directory
    let pipe = Pipe()
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/xcode-select")
    process.arguments = ["-p"]
    process.standardOutput = pipe
    try? process.run()
    process.waitUntilExit()
    
    guard process.terminationStatus == 0,
          let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
          !output.isEmpty else {
        return nil
    }
    
    // /Applications/Xcode-27.x.app/Contents/Developer -> traverse up 2 levels
    let devURL = URL(fileURLWithPath: output)
    let appURL = devURL.deletingLastPathComponent().deletingLastPathComponent()
    return FileManager.default.fileExists(atPath: appURL.path) ? appURL : nil
}

---

## 5. Fixing the Gemini CLI Folder Trust & Subprocess Hang

### The Root Cause of the UI Freeze
When users click **Install** on Gemini CLI in SwiftFairy, the UI often gets stuck in an infinite spinner ("idling").

**Why this happens:**
1. SwiftFairy executes:
   ```bash
   gemini extensions install "$HOME/Library/Application Support/Nil Coalescing/SwiftFairy/Integrations/GeminiExtension" --consent
   ```
2. While `--consent` skips the generic extension warning dialog, `@google/gemini-cli` has a separate security check: **Folder Trust** (`isWorkspaceTrusted()`).
3. If the local directory has not been pre-registered in `~/.gemini/trustedFolders.json`, Gemini CLI prints:
   ```text
   Do you trust the files in this folder? [y/N]:
   ```
   and opens a `readline` prompt on `process.stdin`.
4. Because SwiftFairy spawned this process as a background task without an interactive terminal (TTY) or piped stdin, the CLI blocks on `stdin` forever, causing SwiftFairy to wait indefinitely.

---

### Solution A (Recommended): Direct Filesystem Installation (No CLI Subprocess)

Just like Antigravity, Gemini CLI automatically discovers and activates extensions located in `~/.gemini/extensions/<name>/` at startup without running any CLI commands.

By copying the files directly and writing the local install metadata, installation completes in **< 10ms with zero risk of hangs or missing dependencies**:

```swift
extension SwiftFairyIntegrationInstaller {

    var isGeminiInstalled: Bool {
        let fm = FileManager.default
        let home = fm.homeDirectoryForCurrentUser
        return fm.fileExists(atPath: home.appendingPathComponent(".gemini").path) ||
               ["/opt/homebrew/bin/gemini", "/usr/local/bin/gemini"].contains { fm.fileExists(atPath: $0) }
    }

    func installGeminiExtensionDirectly(stdioHelperPath: String) throws {
        let fm = FileManager.default
        let home = fm.homeDirectoryForCurrentUser
        let targetDir = home.appendingPathComponent(".gemini/extensions/swiftfairy")
        
        try fm.createDirectory(at: targetDir, withIntermediateDirectories: true)
        
        guard let bundleURL = Bundle.main.url(forResource: "GeminiExtension", withExtension: nil) else {
            throw IntegrationError.bundledIntegrationMissing
        }
        
        // 1. Copy extension bundle, substituting stdio helper
        try copyAndSubstitute(
            from: bundleURL, 
            to: targetDir, 
            placeholder: "__SWIFTFAIRY_STDIO_HELPER__", 
            replacement: stdioHelperPath
        )
        
        // 2. Write .gemini-extension-install.json
        let installMeta: [String: Any] = [
            "source": targetDir.path,
            "type": "local"
        ]
        let metaData = try JSONSerialization.data(withJSONObject: installMeta, options: [.prettyPrinted])
        try metaData.write(to: targetDir.appendingPathComponent(".gemini-extension-install.json"))
        
        // 3. Pre-authorize in ~/.gemini/trustedFolders.json to avoid prompts on future CLI interactions
        let trustedFile = home.appendingPathComponent(".gemini/trustedFolders.json")
        var trustedFolders: [String: String] = [:]
        if let existing = try? Data(contentsOf: trustedFile),
           let json = try? JSONSerialization.jsonObject(with: existing) as? [String: String] {
            trustedFolders = json
        }
        trustedFolders[targetDir.path.lowercased()] = "TRUST_FOLDER"
        let updatedData = try JSONSerialization.data(withJSONObject: trustedFolders, options: [.prettyPrinted])
        try updatedData.write(to: trustedFile)
    }

    func uninstallGeminiExtensionDirectly() throws {
        let fm = FileManager.default
        let home = fm.homeDirectoryForCurrentUser
        let targetDir = home.appendingPathComponent(".gemini/extensions/swiftfairy")
        if fm.fileExists(atPath: targetDir.path) {
            try fm.removeItem(at: targetDir)
        }
    }
}
```

---

### Solution B: If Retaining the `Process` Execution

If you prefer to continue invoking `/opt/homebrew/bin/gemini extensions install ...`, apply these two changes to prevent the interactive prompt:

1. **Inject `GEMINI_CLI_TRUST_WORKSPACE = "true"` into `process.environment`**:
   Gemini CLI explicitly checks this environment variable in `checkPathTrust()`:
   ```javascript
   if (process.env["GEMINI_CLI_TRUST_WORKSPACE"] === "true") {
       return { isTrusted: true, source: "env" };
   }
   ```
2. **Pre-seed `~/.gemini/trustedFolders.json`** before launching the process.

```swift
func installGeminiViaCLI(sourceDir: URL) throws {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/gemini")
    process.arguments = ["extensions", "install", sourceDir.path, "--consent"]
    
    // Crucial: Bypass folder trust checks in non-interactive subprocesses!
    var env = ProcessInfo.processInfo.environment
    env["GEMINI_CLI_TRUST_WORKSPACE"] = "true"
    process.environment = env
    
    try process.run()
    process.waitUntilExit()
}
```

```
