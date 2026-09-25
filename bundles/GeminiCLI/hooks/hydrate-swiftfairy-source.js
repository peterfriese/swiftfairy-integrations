ObjC.import("Foundation");

const sourceMarker = "swiftfairy://workspace-file";
// Tells SwiftFairy this source never entered model context, for its savings estimate.
const privateTransfer = "private";

function unwrap(value) {
  return ObjC.unwrap(value);
}

function readStandardInput() {
  const data = $.NSFileHandle.fileHandleWithStandardInput.readDataToEndOfFile;
  const string = $.NSString.alloc.initWithDataEncoding(data, $.NSUTF8StringEncoding);
  if (!string) throw new Error("The hook input is not valid UTF-8.");
  return unwrap(string);
}

function writeStandardOutput(value) {
  const data = $(JSON.stringify(value)).dataUsingEncoding($.NSUTF8StringEncoding);
  $.NSFileHandle.fileHandleWithStandardOutput.writeData(data);
}

function canonicalPath(path) {
  return unwrap($(path).stringByStandardizingPath.stringByResolvingSymlinksInPath);
}

function environmentValue(name) {
  const value = unwrap($.NSProcessInfo.processInfo.environment.objectForKey(name));
  return typeof value === "string" && value.length > 0 ? value : null;
}

// The session's working directory can drift into a subdirectory, so paths may be relative to
// either the project root the host reports or the current directory.
function workspaceRoots(input) {
  const candidates = [
    environmentValue("CLAUDE_PROJECT_DIR"),
    environmentValue("GEMINI_PROJECT_DIR"),
    input.cwd || unwrap($.NSFileManager.defaultManager.currentDirectoryPath)
  ];
  const roots = [];
  for (const candidate of candidates) {
    if (!candidate) continue;
    const root = canonicalPath(candidate);
    if (!roots.includes(root)) roots.push(root);
  }
  return roots;
}

function existingFileInside(relativePath, root) {
  const candidate = canonicalPath(unwrap($(root).stringByAppendingPathComponent(relativePath)));
  if (candidate !== root && !candidate.startsWith(root + "/")) return null;
  const isDirectory = Ref();
  if (!$.NSFileManager.defaultManager.fileExistsAtPathIsDirectory(candidate, isDirectory)) return null;
  return isDirectory[0] ? null : candidate;
}

function sourceAt(relativePath, roots) {
  if (relativePath.startsWith("/") || relativePath.split("/").includes("..")) {
    throw new Error(`SwiftFairy source path ${relativePath} must be relative to the workspace.`);
  }
  if (!relativePath.endsWith(".swift")) {
    throw new Error(`SwiftFairy private source transfer accepts only .swift files, not ${relativePath}.`);
  }

  let file = null;
  for (const root of roots) {
    file = existingFileInside(relativePath, root);
    if (file) break;
  }
  if (!file) {
    throw new Error(
      `SwiftFairy source ${relativePath} was not found inside the workspace (${roots.join(", ")}).`
    );
  }
  const source = $.NSString.stringWithContentsOfFileEncodingError(file, $.NSUTF8StringEncoding, null);
  if (!source) throw new Error(`SwiftFairy source ${relativePath} is not valid UTF-8.`);
  return unwrap(source);
}

function hydrate(value, roots) {
  if (Array.isArray(value)) {
    return value.map(item => hydrate(item, roots));
  }
  if (!value || typeof value !== "object") return value;

  const result = {};
  for (const key of Object.keys(value)) {
    result[key] = hydrate(value[key], roots);
  }
  if (value.content === sourceMarker && typeof value.path === "string") {
    result.content = sourceAt(value.path, roots);
    result.transfer = privateTransfer;
  } else if ("transfer" in result && typeof result.content === "string") {
    // Only this hook may assert private transfer; model-authored source does not qualify.
    delete result.transfer;
  }
  return result;
}

function response(eventName, toolInput) {
  if (eventName === "BeforeTool") {
    return {
      decision: "allow",
      suppressOutput: true,
      hookSpecificOutput: {
        hookEventName: "BeforeTool",
        tool_input: toolInput
      }
    };
  }
  return {
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "allow",
      updatedInput: toolInput
    }
  };
}

function rejection(eventName, message) {
  if (eventName === "BeforeTool") {
    return { decision: "deny", reason: message };
  }
  return {
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: message
    }
  };
}

let eventName = "PreToolUse";
try {
  const input = JSON.parse(readStandardInput());
  eventName = input.hook_event_name || eventName;
  const toolInput = hydrate(input.tool_input || {}, workspaceRoots(input));
  writeStandardOutput(response(eventName, toolInput));
} catch (error) {
  writeStandardOutput(rejection(eventName, String(error.message || error)));
}
