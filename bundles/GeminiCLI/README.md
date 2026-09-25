# SwiftFairy Extension for Gemini CLI

This bundle provides a robust, pre-authorized extension for the **Gemini CLI** (`@google/gemini-cli`).

## 📁 Bundle Contents

* **`gemini-extension.json`**: Gemini CLI extension manifest registering MCP tools.
* **`GEMINI.md`**: Extension context instructions for the Gemini CLI agent.
* **`.gemini-extension-install.json`**: Local installation marker enabling instant discovery without interactive network/prompt overhead.
* **`hooks/`**:
  * `hooks.json`: Lifecycle hook definitions for `PreToolUse`.
  * `hydrate-swiftfairy-source.js`: Direct file-read and buffer hydration script.
* **`skills/swiftfairy/SKILL.md`**: Detailed skill rules for SwiftFairy AST auditing and guidance retrieval.

## 🛠️ Installation Paths

* Target Extension Directory: `~/.gemini/extensions/swiftfairy/`
* Security Pre-Authorization File: `~/.gemini/trustedFolders.json`

## 💡 The Folder Trust & TTY Hang Fix

Previous versions froze during installation because Gemini CLI executes a folder trust check (`isWorkspaceTrusted()`) on interactive `process.stdin`. This bundle eliminates the hang in two ways:
1. **Direct Filesystem Placement**: Placing the bundle directly into `~/.gemini/extensions/swiftfairy/` completely avoids invoking `gemini extensions install` as an external subprocess.
2. **Pre-Authorized Folder Trust**: Marking `~/.gemini/extensions/swiftfairy` as `"TRUST_FOLDER"` in `~/.gemini/trustedFolders.json` ensures future CLI invocations never block on a headless `[y/N]` prompt.

## 🚀 Quick Setup

### Using the Standalone Installer
```bash
./swiftfairy-standin install gemini
```

### Manual Installation
1. Create the extension directory:
   ```bash
   mkdir -p ~/.gemini/extensions/swiftfairy
   ```
2. Copy all files from `bundles/GeminiCLI/` into `~/.gemini/extensions/swiftfairy/`.
3. In `gemini-extension.json`, replace `__SWIFTFAIRY_STDIO_HELPER__` with your helper binary path.
4. Pre-register folder trust in `~/.gemini/trustedFolders.json`:
   ```json
   {
     "/users/<username>/.gemini/extensions/swiftfairy": "TRUST_FOLDER"
   }
   ```
