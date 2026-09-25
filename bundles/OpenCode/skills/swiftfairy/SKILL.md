---
name: swiftfairy
description: Use the local SwiftFairy reference service when reviewing Swift or SwiftUI code, auditing code changes, or looking for best practices for an Apple framework API, modifier, or domain. It returns bounded findings and citations from installed SwiftFairy scrolls.
---

# SwiftFairy

Use SwiftFairy as a reference reviewer. Do not reproduce its rules by searching for particular syntax yourself.

- Use `swiftfairy.audit_code` for focused existing-code audits.
- Use `swiftfairy.audit_batches` for repository reviews, grouping related files into up to six batches of at most eight files. Retry only batches that do not complete.
- Use `swiftfairy.audit_changes` while editing, with the changed code and nearby declarations or call sites.
- Use `swiftfairy.find_guidance` before work on an API, modifier, concept, or domain. It returns 10 references by default, strongest first; pass `limit` (1–20) to change that.

Send small Swift fragments. They need not compile or contain complete files. If SwiftFairy asks for context, follow Context follow-ups below and submit the audit again. Do not claim a complete audit when a request or file was omitted. Pass `projectRoot` (the absolute path of the workspace or package root) on every audit call so SwiftFairy can read declarations from the project's own modules and its package dependencies instead of asking for them; add `packagePaths` only for local packages outside that root. Declarations it read this way are listed in `autoSupplied`; still supply anything it asks for.

## Use the complete guidance

Tool-result excerpts are for triage, not for reporting or implementation. Before reporting a finding to the user, recommending or making a change because of it, or applying a `find_guidance` result, read its primary `resourceURI`. Read additional linked references when they describe the proposed solution or a relevant exception. Base the response or change on the complete guidance, its examples, and the actual code and usage context rather than on the one-line summary.

Interpret guidance levels as follows:

- `MUST` and `MUST NOT` prescribe the outcome once the guidance's applicability is established.
- `SHOULD` and `SHOULD NOT` provide a recommended default with legitimate, explained exceptions.
- `CONSIDER` requires contextual evaluation. Read the complete linked guidance and determine from the surrounding code, requirements, and usage whether the result is a required change, a recommendation, or no change because a documented exception applies. Never treat `CONSIDER` as merely stylistic, low priority, or safe to ignore.
- `MAY` identifies a permitted option without recommending its adoption.

Keep guidance strength separate from match certainty and result order. Do not repeat SwiftFairy's standard limitations or certainty boilerplate to the user. Mention a limitation only when it materially affects the requested conclusion, leaves a specific finding unresolved, omits requested scope, or requires more context; attach it concisely to the affected finding.

## Source transfer

Do not read Swift source into the model context solely to relay it to SwiftFairy, and do not ask the user to paste source that the host can already access. When the host provides private tool chaining or pre-tool argument rewriting, use it to read source and populate SwiftFairy arguments without returning the intermediate source to the model. If no such facility is available, submit only source that is already present in the task context; do not initiate additional source-bearing reads merely to construct an audit request. This restriction does not prevent reading source when the user's primary coding task itself requires inspection or editing.

## Context follow-ups

When a result is `needs_context`, supply only what it names:

- Find each requested symbol with a targeted search scoped by its owner and module (`owner`, `file`, `sourceModule`). Never match a bare generic-parameter, standard-library, or framework-protocol name such as `View`, `Index`, or `Value`. Do not write repository-index, dependency-planning, or SDK-extraction scripts.
- Send the owning type or extension declaration rather than the whole file.
- For an app declaration, supply it. Send a small public declaration only when the request names a type the app itself declares or imports from a non-Apple package; for Apple SDK types send nothing and mark the request unresolved. Never invent or paste framework implementation bodies, and do not answer a generic or existential question with a file hunt.
- Retry once for each new piece of context. If the same request comes back after its declaration was sent, or nothing new can be supplied, stop and mark it unresolved.
- `files`, `supportingFiles`, `currentFiles`, and `previousFiles` each hold at most eight entries. On a retry, replace earlier support with what the new request names rather than adding to it; split the group if it still does not fit.
- In the final report, list rejected groups (submission errors), groups still `needs_context` with their unresolved requests, and framework limits separately. Report locations as returned; label any location you checked by hand, and never substitute the nearest matching name.

## Rule suppression

Only add, widen, or remove suppression comments when the user explicitly directs you to do so. Never suppress a finding merely to make an audit pass. SwiftFairy recognizes Swift `//` line comments, not block comments. Use the narrowest scope and selector that satisfies the request. Selectors may be an exact rule ID, a terminal prefix wildcard such as `swiftui-guardrails-concurrent-*`, or the blanket `*`; multiple selectors are separated by spaces, and an optional reason follows ` - `.

```swift
// swiftfairy:disable:next prefer-observation
let model = LegacyModel()

view.bold() // swiftfairy:disable prefer-observation swiftui-guardrails-concurrent-* - Intentional here

// swiftfairy:disable:file swiftui-guardrails-concurrent-*

// swiftfairy:disable prefer-observation
// ...suppressed region...
// swiftfairy:enable prefer-observation
```

A trailing unmodified `disable` applies to its current line. A standalone unmodified `disable` starts a region that must be closed by a matching `enable`. Explicit `:this` and `:previous` scopes are also supported.

Put `swiftfairy:disable:next` directly above the line of the flagged modifier, such as `.environment(...)`, not above the first line of its chain.

When directed to remove a suppression, delete its whole line or trailing comment. If a directive contains several selectors, remove only the requested selector and retain the others. For a region, remove the selector from both its `disable` and matching `enable`, deleting both comments when no selectors remain. Preserve an existing reason only while it still describes the remaining suppression.

For a temporary audit-only suppression, pass selectors in `disabledRules` to `swiftfairy.audit_code` or `swiftfairy.audit_changes`, or on the relevant `swiftfairy.audit_batches` batch. This does not edit the source or persist. Use `disabledRules: ["*"]` only when the user explicitly requests a blanket audit suppression; omit the field or selector on the next audit to remove it.
