---
name: blender-mcp
description: Inspect and edit Blender scenes, run Blender Python, and consult Blender API or manual documentation using the local Blender Lab MCP server. Use for tasks involving Blender or .blend files.
---

# Blender MCP

Use the Blender Lab server installed by this dotfiles configuration. If Blender
MCP tools are already available in the session, use them directly. Otherwise,
use `scripts/client.py` relative to this skill directory; it starts the pinned
server over stdio for each invocation. No Codex installation or MCP config
change is needed. Run the installed helper directly, so its Nix Python
interpreter and dependencies are used.

```sh
~/.agents/skills/blender-mcp/scripts/client.py list
~/.agents/skills/blender-mcp/scripts/client.py call get_objects_summary '{}'
~/.agents/skills/blender-mcp/scripts/client.py call execute_blender_code --args-file /tmp/blender-args.json
```

`list` returns tool descriptions and input schemas. Consult those schemas before
calling an unfamiliar tool. `call` accepts a JSON object as an argument, or reads
one from `--args-file` (`-` for stdin). Results are MCP JSON, including `content`,
`structuredContent` when supplied, and `isError`. Image content is base64; decode
it to a file and inspect the image when visual verification is useful.

Scene tools require a running Blender with the **MCP** add-on enabled and
**Allow Online Access** enabled in Preferences → System. The bridge defaults to
`localhost:9876`; its **Auto Start** preference starts it when Blender opens.
If the bridge is unavailable, report the missing prerequisite. Tool listing
alone does not establish that Blender is connected.

Inspect the current scene and relevant objects before changing them. Prefer
dedicated inspection tools; use `execute_blender_code` for edits or operations
they do not cover. Consult the server's API/manual tools for version-specific
details. Verify changes by reading back scene state or rendering a preview.
Saving or exporting should use the destination intended by the user; scene
edits are not automatically saved to disk.

Each helper call starts a fresh MCP process but interacts with the same running
Blender. A timeout or lost connection does not prove an edit failed: inspect
state before retrying an operation that could duplicate objects or edits.
