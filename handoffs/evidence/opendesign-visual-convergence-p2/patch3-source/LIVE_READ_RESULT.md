# Patch 3 — Notification live source read result

TASK=OPENDESIGN_P2_PATCH3_NOTIFICATION_LIVE_SOURCE_CAPTURE
WORKSTREAM_ID=OPENDESIGN_VISUAL_CONVERGENCE_P2
ROLE=LIVE_DESIGN_READER
READ_AT_HEAD=f6b8e1e311ca7f3e902d742f98dd8ddb17e63dd0

## Attempted surface

Requested target:

```text
OPEN_DESIGN_PROJECT_NAME=FST Design Exploration
OPEN_DESIGN_PROJECT_ID=988fea7b-beea-4916-a10e-5368a120417e
```

Requested read-only calls:

```text
list_projects
get_project
get_file
search_files
list_files
```

## Result

```text
LIVE_SOURCE_READ=NO
LIVE_SOURCE_FAILURE=OpenDesign/Muse MCP read tools are not exposed on the
  currently available OpenCode/Muse tool surface for this session. No
  list_projects / get_project / get_file / search_files / list_files tool is
  present in the session tool list, and the repository .mcp.json declares only
  the fst-codegraph MCP server. Therefore no live OpenDesign call could be
  issued.
FALLBACK_SOURCE_USED=YES
```

## Evidence for the failure (measured, not inferred)

1. Session tool surface available to this Worker contains no MCP tool of any
   kind. There is therefore no OpenDesign read entry point to call.
2. Repository `/Users/cenvu/DEV/FST_V2/.mcp.json` declares exactly one server:

   ```json
   { "mcpServers": { "fst-codegraph": { "type": "stdio",
     "command": "/Users/cenvu/DEV/FST_V2/FST_AI/tools/fst-codegraph-mcp.sh",
     "args": [], "env": {} } } }
   ```

   It contains no OpenDesign/Muse server.
3. Global OpenCode config `~/.config/opencode/opencode.json` declares a
   provider block only; it declares no `mcpServers` block at all.
4. `muse skills list` returns only built-in/user product skills (create-skill,
   doctor, git, grill, grill-and-record, import, manage-settings, plan,
   read-session, taste, ego-browser). No OpenDesign project-read skill exists.

No repair, reconfiguration, or transport restart was attempted. That is
explicitly out of scope for this task (`NO_TOOLING_REPAIR`,
`Do NOT investigate or repair Codex/OpenDesign configuration`).

## Comparison against frozen source

Because `LIVE_SOURCE_READ=NO`, no live-vs-frozen comparison of Notification
regions was possible. Per Section 4 of the task brief, the canonical frozen
live-source snapshot is used as the design authority for this bounded Patch 3
handoff.

## Fallback source used

```text
handoffs/evidence/opendesign-live-transfer-p1/live-source/index.html
handoffs/evidence/opendesign-live-transfer-p1/live-source/assets/fst-c.css
handoffs/evidence/opendesign-live-transfer-p1/live-source/assets/fst-c.js
```

Measured SHA256 and size of the fallback files:

```text
b70202cafe7eb1e5503ee7c7178dc1ab80e1266e2078f1b3576b0adb899fb9e8  index.html      8007 bytes
a6170ef2c70fc770440271640b172f5b6fa0c44684d5dcea9d5bf2596dc3f8e5  assets/fst-c.css 34091 bytes
aaa3bd496796890c63d42190ac8ad333ab4c299c5cf7530085aa85a9ba132a66  assets/fst-c.js  44966 bytes
```

## Not asserted

Whether the live OpenDesign project currently differs from this frozen
snapshot for Notification regions is UNKNOWN. It was not measured and must
not be inferred.
