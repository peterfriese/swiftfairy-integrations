//
//  SwiftFairyIntegrationInstaller.swift
//  SwiftFairy
//
//  Created for SwiftFairy / Nil Coalescing Limited.
//  Production-ready, drop-in integration manager supporting modern AI coding agents:
//  - Google Antigravity (Agent Manager & CLI)
//  - Antigravity IDE (with complete MCP, Skill, and Rules support)
//  - Gemini CLI (with zero-hang Folder Trust pre-authorization)
//  - OpenCode & OpenChamber (with comment-safe JSONC and skills)
//

import Foundation

// MARK: - Supported Agents

public enum SwiftFairyAgent: String, CaseIterable, Identifiable, Sendable {
    case antigravity = "antigravity"
    case antigravityIDE = "antigravity-ide"
    case geminiCLI = "gemini"
    case openCode = "opencode"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .antigravity:
            return "Google Antigravity (Agent Manager / CLI)"
        case .antigravityIDE:
            return "Antigravity IDE"
        case .geminiCLI:
            return "Gemini CLI"
        case .openCode:
            return "OpenCode & OpenChamber"
        }
    }

    public var bundleResourceName: String {
        switch self {
        case .antigravity:
            return "AntigravityPlugin"
        case .antigravityIDE:
            return "AntigravityIDE"
        case .geminiCLI:
            return "GeminiCLI"
        case .openCode:
            return "OpenCode"
        }
    }
}

// MARK: - Integration Status

public enum IntegrationStatus: Equatable, Sendable {
    case notFound
    case detected(readyToInstall: Bool)
    case installed
    case error(String)
}

// MARK: - Integration Errors

public enum IntegrationError: LocalizedError, Sendable {
    case bundledIntegrationMissing(String)
    case helperBinaryMissing(String)
    case fileSystemError(String)
    case serializationError(String)
    case agentNotDetected(SwiftFairyAgent)

    public var errorDescription: String? {
        switch self {
        case .bundledIntegrationMissing(let name):
            return "Bundled resource '\(name)' could not be located in application bundle."
        case .helperBinaryMissing(let path):
            return "SwiftFairy stdio helper binary not found at '\(path)'."
        case .fileSystemError(let detail):
            return "Filesystem operation failed: \(detail)"
        case .serializationError(let detail):
            return "JSON configuration error: \(detail)"
        case .agentNotDetected(let agent):
            return "\(agent.displayName) was not detected on this system."
        }
    }
}

// MARK: - SwiftFairyIntegrationInstaller

public final class SwiftFairyIntegrationInstaller: @unchecked Sendable {

    public static let shared = SwiftFairyIntegrationInstaller()

    private let fileManager: FileManager
    private let homeDirectory: URL

    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        self.homeDirectory = fileManager.homeDirectoryForCurrentUser
    }

    // MARK: - Helper Binary Resolution

    public var defaultStdioHelperURL: URL? {
        let appBundleHelper = Bundle.main.bundleURL
            .appendingPathComponent("Contents/Helpers/swiftfairy-stdio")
        if fileManager.isExecutableFile(atPath: appBundleHelper.path) {
            return appBundleHelper
        }

        let installedAppHelper = URL(fileURLWithPath: "/Applications/SwiftFairy.app/Contents/Helpers/swiftfairy-stdio")
        if fileManager.isExecutableFile(atPath: installedAppHelper.path) {
            return installedAppHelper
        }

        if let envPath = ProcessInfo.processInfo.environment["SWIFTFAIRY_STDIO_PATH"],
           fileManager.isExecutableFile(atPath: envPath) {
            return URL(fileURLWithPath: envPath)
        }

        return nil
    }

    // MARK: - Status Queries

    public func status(for agent: SwiftFairyAgent) -> IntegrationStatus {
        switch agent {
        case .antigravity:
            if isAntigravityPluginInstalled { return .installed }
            if isAntigravityDetected { return .detected(readyToInstall: true) }
            return .notFound

        case .antigravityIDE:
            if isAntigravityIDEConfigured { return .installed }
            if isAntigravityIDEDetected { return .detected(readyToInstall: true) }
            return .notFound

        case .geminiCLI:
            if isGeminiExtensionInstalled { return .installed }
            if isGeminiDetected { return .detected(readyToInstall: true) }
            return .notFound

        case .openCode:
            if isOpenCodeConfigured { return .installed }
            if isOpenCodeDetected { return .detected(readyToInstall: true) }
            return .notFound
        }
    }

    public func checkAllStatuses() -> [SwiftFairyAgent: IntegrationStatus] {
        var results: [SwiftFairyAgent: IntegrationStatus] = [:]
        for agent in SwiftFairyAgent.allCases {
            results[agent] = status(for: agent)
        }
        return results
    }

    // MARK: - 1. Google Antigravity (Agent Manager & CLI)

    public var isAntigravityDetected: Bool {
        let pluginParent = homeDirectory.appendingPathComponent(".gemini/antigravity")
        let candidateCLIs = [
            "/opt/homebrew/bin/agy",
            "/usr/local/bin/agy",
            homeDirectory.appendingPathComponent(".local/bin/agy").path
        ]
        return fileManager.fileExists(atPath: pluginParent.path) ||
               candidateCLIs.contains { fileManager.fileExists(atPath: $0) }
    }

    public var isAntigravityPluginInstalled: Bool {
        let pluginDir = homeDirectory.appendingPathComponent(".gemini/antigravity/plugins/swiftfairy")
        let pluginJSON = pluginDir.appendingPathComponent("plugin.json")
        let mcpConfig = pluginDir.appendingPathComponent("mcp_config.json")
        return fileManager.fileExists(atPath: pluginJSON.path) &&
               fileManager.fileExists(atPath: mcpConfig.path)
    }

    public func installAntigravityPlugin(stdioHelperPath: String, bundleURL: URL? = nil) throws {
        let targetDir = homeDirectory.appendingPathComponent(".gemini/antigravity/plugins/swiftfairy")
        let sourceURL = try resolveBundle(named: SwiftFairyAgent.antigravity.bundleResourceName, explicitURL: bundleURL)

        try copyTreeWithSubstitutions(
            from: sourceURL,
            to: targetDir,
            replacements: ["__SWIFTFAIRY_STDIO_HELPER__": stdioHelperPath]
        )
    }

    public func uninstallAntigravityPlugin() throws {
        let targetDir = homeDirectory.appendingPathComponent(".gemini/antigravity/plugins/swiftfairy")
        if fileManager.fileExists(atPath: targetDir.path) {
            try fileManager.removeItem(at: targetDir)
        }
    }

    // MARK: - 2. Antigravity IDE

    public var isAntigravityIDEDetected: Bool {
        let appSupport = homeDirectory.appendingPathComponent("Library/Application Support/Antigravity IDE")
        return fileManager.fileExists(atPath: appSupport.path) ||
               fileManager.fileExists(atPath: "/Applications/Antigravity IDE.app")
    }

    public var antigravityIDEMCPConfigURL: URL {
        homeDirectory.appendingPathComponent("Library/Application Support/Antigravity IDE/User/mcp.json")
    }

    public var antigravityIDESkillURL: URL {
        homeDirectory.appendingPathComponent(".gemini/antigravity/skills/swiftfairy/SKILL.md")
    }

    public var isAntigravityIDEConfigured: Bool {
        guard let data = try? Data(contentsOf: antigravityIDEMCPConfigURL),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let servers = json["mcpServers"] as? [String: Any] else {
            return false
        }
        return servers["swiftfairy"] != nil && fileManager.fileExists(atPath: antigravityIDESkillURL.path)
    }

    public func installAntigravityIDE(stdioHelperPath: String, bundleURL: URL? = nil) throws {
        let configURL = antigravityIDEMCPConfigURL
        try fileManager.createDirectory(at: configURL.deletingLastPathComponent(), withIntermediateDirectories: true)

        // 1. Configure MCP server in Antigravity IDE User settings
        var json = (try? loadJSON(at: configURL)) ?? [:]
        var servers = json["mcpServers"] as? [String: Any] ?? [:]
        servers["swiftfairy"] = [
            "command": stdioHelperPath,
            "args": []
        ]
        json["mcpServers"] = servers
        try saveJSON(json, to: configURL)

        // 2. Deploy Skill so Antigravity IDE agent has the complete guidance rules
        let sourceURL = try resolveBundle(named: SwiftFairyAgent.antigravityIDE.bundleResourceName, explicitURL: bundleURL)
        let skillSource = sourceURL.appendingPathComponent("skills/swiftfairy/SKILL.md")
        if fileManager.fileExists(atPath: skillSource.path) {
            let skillTargetDir = antigravityIDESkillURL.deletingLastPathComponent()
            try fileManager.createDirectory(at: skillTargetDir, withIntermediateDirectories: true)
            if fileManager.fileExists(atPath: antigravityIDESkillURL.path) {
                try fileManager.removeItem(at: antigravityIDESkillURL)
            }
            try fileManager.copyItem(at: skillSource, to: antigravityIDESkillURL)
        }
    }

    public func uninstallAntigravityIDE() throws {
        let configURL = antigravityIDEMCPConfigURL
        if fileManager.fileExists(atPath: configURL.path),
           var json = try? loadJSON(at: configURL),
           var servers = json["mcpServers"] as? [String: Any] {
            servers.removeValue(forKey: "swiftfairy")
            json["mcpServers"] = servers
            try? saveJSON(json, to: configURL)
        }

        let skillTargetDir = antigravityIDESkillURL.deletingLastPathComponent()
        if fileManager.fileExists(atPath: skillTargetDir.path) {
            try? fileManager.removeItem(at: skillTargetDir)
        }
    }

    // MARK: - 3. Gemini CLI (Direct Placement + Folder Trust Fix)

    public var isGeminiDetected: Bool {
        let geminiDir = homeDirectory.appendingPathComponent(".gemini")
        let candidateCLIs = [
            "/opt/homebrew/bin/gemini",
            "/usr/local/bin/gemini",
            homeDirectory.appendingPathComponent(".local/bin/gemini").path
        ]
        return fileManager.fileExists(atPath: geminiDir.path) ||
               candidateCLIs.contains { fileManager.fileExists(atPath: $0) }
    }

    public var isGeminiExtensionInstalled: Bool {
        let targetDir = homeDirectory.appendingPathComponent(".gemini/extensions/swiftfairy")
        let manifest = targetDir.appendingPathComponent("gemini-extension.json")
        return fileManager.fileExists(atPath: manifest.path)
    }

    public func installGeminiExtensionDirectly(stdioHelperPath: String, bundleURL: URL? = nil) throws {
        let targetDir = homeDirectory.appendingPathComponent(".gemini/extensions/swiftfairy")
        let sourceURL = try resolveBundle(named: SwiftFairyAgent.geminiCLI.bundleResourceName, explicitURL: bundleURL)

        // 1. Copy files and substitute placeholders
        try copyTreeWithSubstitutions(
            from: sourceURL,
            to: targetDir,
            replacements: [
                "__SWIFTFAIRY_STDIO_HELPER__": stdioHelperPath,
                "__EXTENSION_DIR__": targetDir.path
            ]
        )

        // 2. Ensure .gemini-extension-install.json is written
        let installMetaURL = targetDir.appendingPathComponent(".gemini-extension-install.json")
        let metaDict: [String: Any] = [
            "source": targetDir.path,
            "type": "local"
        ]
        try saveJSON(metaDict, to: installMetaURL)

        // 3. Pre-authorize in ~/.gemini/trustedFolders.json to avoid TTY hang
        try preAuthorizeGeminiFolderTrust(for: targetDir.path)
    }

    public func uninstallGeminiExtensionDirectly() throws {
        let targetDir = homeDirectory.appendingPathComponent(".gemini/extensions/swiftfairy")
        if fileManager.fileExists(atPath: targetDir.path) {
            try fileManager.removeItem(at: targetDir)
        }
    }

    private func preAuthorizeGeminiFolderTrust(for folderPath: String) throws {
        let trustedFile = homeDirectory.appendingPathComponent(".gemini/trustedFolders.json")
        try fileManager.createDirectory(at: trustedFile.deletingLastPathComponent(), withIntermediateDirectories: true)

        var trustedFolders: [String: String] = [:]
        if let existingData = try? Data(contentsOf: trustedFile),
           let json = try? JSONSerialization.jsonObject(with: existingData) as? [String: String] {
            trustedFolders = json
        }

        // Gemini CLI normalizes trusted paths to lowercase
        trustedFolders[folderPath.lowercased()] = "TRUST_FOLDER"
        let updatedData = try JSONSerialization.data(withJSONObject: trustedFolders, options: [.prettyPrinted, .sortedKeys])
        try updatedData.write(to: trustedFile, options: [.atomic])
    }

    // MARK: - 4. OpenCode & OpenChamber

    public var isOpenCodeDetected: Bool {
        let opencodeDir = homeDirectory.appendingPathComponent(".config/opencode")
        let openchamberDir = homeDirectory.appendingPathComponent(".config/openchamber")
        let candidateCLIs = [
            "/Applications/OpenCode.app",
            "/opt/homebrew/bin/opencode",
            "/usr/local/bin/opencode",
            homeDirectory.appendingPathComponent(".local/bin/opencode").path
        ]
        return fileManager.fileExists(atPath: opencodeDir.path) ||
               fileManager.fileExists(atPath: openchamberDir.path) ||
               candidateCLIs.contains { fileManager.fileExists(atPath: $0) }
    }

    public var openCodeConfigURL: URL {
        homeDirectory.appendingPathComponent(".config/opencode/opencode.jsonc")
    }

    public var isOpenCodeConfigured: Bool {
        guard let data = try? Data(contentsOf: openCodeConfigURL),
              let text = String(data: data, encoding: .utf8) else {
            return false
        }
        let stripped = stripJSONComments(text)
        guard let json = try? JSONSerialization.jsonObject(with: Data(stripped.utf8)) as? [String: Any],
              let mcp = json["mcp"] as? [String: Any] else {
            return false
        }
        return mcp["swiftfairy"] != nil
    }

    public func installOpenCodeIntegration(stdioHelperPath: String, bundleURL: URL? = nil) throws {
        let configURL = openCodeConfigURL
        try fileManager.createDirectory(at: configURL.deletingLastPathComponent(), withIntermediateDirectories: true)

        // 1. Merge MCP into opencode.jsonc
        var json: [String: Any] = [:]
        if let data = try? Data(contentsOf: configURL),
           let text = String(data: data, encoding: .utf8) {
            let stripped = stripJSONComments(text)
            json = (try? JSONSerialization.jsonObject(with: Data(stripped.utf8)) as? [String: Any]) ?? [:]
        }

        var mcpDict = json["mcp"] as? [String: Any] ?? [:]
        mcpDict["swiftfairy"] = [
            "type": "local",
            "command": [stdioHelperPath],
            "enabled": true
        ]
        json["mcp"] = mcpDict
        try saveJSON(json, to: configURL)

        // 2. Install Skill
        let targetSkillDir = homeDirectory.appendingPathComponent(".config/opencode/skills/swiftfairy")
        try fileManager.createDirectory(at: targetSkillDir, withIntermediateDirectories: true)

        let sourceURL = try resolveBundle(named: SwiftFairyAgent.openCode.bundleResourceName, explicitURL: bundleURL)
        let skillSource = sourceURL.appendingPathComponent("skills/swiftfairy/SKILL.md")
        if fileManager.fileExists(atPath: skillSource.path) {
            let dest = targetSkillDir.appendingPathComponent("SKILL.md")
            if fileManager.fileExists(atPath: dest.path) {
                try fileManager.removeItem(at: dest)
            }
            try fileManager.copyItem(at: skillSource, to: dest)
        }
    }

    public func uninstallOpenCodeIntegration() throws {
        let configURL = openCodeConfigURL
        if let data = try? Data(contentsOf: configURL),
           let text = String(data: data, encoding: .utf8) {
            let stripped = stripJSONComments(text)
            if var json = try? JSONSerialization.jsonObject(with: Data(stripped.utf8)) as? [String: Any],
               var mcp = json["mcp"] as? [String: Any] {
                mcp.removeValue(forKey: "swiftfairy")
                json["mcp"] = mcp
                try? saveJSON(json, to: configURL)
            }
        }

        let targetSkillDir = homeDirectory.appendingPathComponent(".config/opencode/skills/swiftfairy")
        if fileManager.fileExists(atPath: targetSkillDir.path) {
            try? fileManager.removeItem(at: targetSkillDir)
        }
    }

    // MARK: - Batch Operations

    public func installAll(stdioHelperPath: String, bundleResolver: ((SwiftFairyAgent) -> URL?)? = nil) throws {
        if isAntigravityDetected {
            try installAntigravityPlugin(stdioHelperPath: stdioHelperPath, bundleURL: bundleResolver?(.antigravity))
        }
        if isAntigravityIDEDetected {
            try installAntigravityIDE(stdioHelperPath: stdioHelperPath, bundleURL: bundleResolver?(.antigravityIDE))
        }
        if isGeminiDetected {
            try installGeminiExtensionDirectly(stdioHelperPath: stdioHelperPath, bundleURL: bundleResolver?(.geminiCLI))
        }
        if isOpenCodeDetected {
            try installOpenCodeIntegration(stdioHelperPath: stdioHelperPath, bundleURL: bundleResolver?(.openCode))
        }
    }

    public func uninstallAll() throws {
        try uninstallAntigravityPlugin()
        try uninstallAntigravityIDE()
        try uninstallGeminiExtensionDirectly()
        try uninstallOpenCodeIntegration()
    }

    // MARK: - Utilities & File System Helpers

    private func resolveBundle(named name: String, explicitURL: URL?) throws -> URL {
        if let explicit = explicitURL, fileManager.fileExists(atPath: explicit.path) {
            return explicit
        }
        if let bundleURL = Bundle.main.url(forResource: name, withExtension: nil) {
            return bundleURL
        }
        // Fallback for command-line tools running alongside bundles/ directory
        let localCandidate = URL(fileURLWithPath: "bundles").appendingPathComponent(name)
        if fileManager.fileExists(atPath: localCandidate.path) {
            return localCandidate
        }
        throw IntegrationError.bundledIntegrationMissing(name)
    }

    public func copyTreeWithSubstitutions(
        from source: URL,
        to destination: URL,
        replacements: [String: String]
    ) throws {
        if fileManager.fileExists(atPath: destination.path) {
            try fileManager.removeItem(at: destination)
        }
        try fileManager.createDirectory(at: destination, withIntermediateDirectories: true)

        guard let enumerator = fileManager.enumerator(
            at: source,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            throw IntegrationError.fileSystemError("Failed to enumerate \(source.path)")
        }

        for case let fileURL as URL in enumerator {
            let relativePath = fileURL.path.replacingOccurrences(of: source.path + "/", with: "")
            let targetURL = destination.appendingPathComponent(relativePath)
            let isDir = (try? fileURL.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false

            if isDir {
                try fileManager.createDirectory(at: targetURL, withIntermediateDirectories: true)
            } else {
                let ext = fileURL.pathExtension.lowercased()
                if ["json", "jsonc", "md", "js", "txt"].contains(ext) {
                    if var text = try? String(contentsOf: fileURL, encoding: .utf8) {
                        for (placeholder, replacement) in replacements {
                            text = text.replacingOccurrences(of: placeholder, with: replacement)
                        }
                        try text.write(to: targetURL, atomically: true, encoding: .utf8)
                        continue
                    }
                }
                try fileManager.copyItem(at: fileURL, to: targetURL)
            }
        }
    }

    public func loadJSON(at url: URL) throws -> [String: Any] {
        let data = try Data(contentsOf: url)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw IntegrationError.serializationError("Root JSON at \(url.path) is not an object.")
        }
        return json
    }

    public func saveJSON(_ json: [String: Any], to url: URL) throws {
        let data = try JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys])
        try data.write(to: url, options: [.atomic])
    }

    private func stripJSONComments(_ text: String) -> String {
        text.components(separatedBy: .newlines)
            .filter { line in
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                return !trimmed.hasPrefix("//")
            }
            .joined(separator: "\n")
    }
}
