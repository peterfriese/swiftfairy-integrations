# Swift & SwiftUI Guidelines: SwiftFairy Integration

When inspecting, generating, or refactoring Swift and SwiftUI code in Antigravity IDE:

1. **Reference Knowledge**:
   - Before introducing or refactoring Apple framework APIs (SwiftUI, Swift Charts, SwiftData, Firebase), invoke `swiftfairy.find_guidance` to retrieve authoritative scrolls and best practices.
   - For code reviews or file audits, invoke `swiftfairy.audit_code` or `swiftfairy.audit_changes`.

2. **Guidance Compliance**:
   - `MUST` and `MUST NOT`: Strictly mandatory outcomes.
   - `SHOULD` and `SHOULD NOT`: Recommended defaults with documented exceptions.
   - `CONSIDER`: Contextual evaluation—never treat as merely stylistic.

3. **Rule Suppression**:
   - Follow standard `// swiftfairy:disable:next <rule-id>` Swift comments when intentionally suppressing specific checks.
