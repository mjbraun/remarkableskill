---
name: remarkable
description: Convert markdown to PDF and push to Remarkable tablet
allowed-tools: Bash, Read, Write
user-invocable: true
---

# Remarkable Push Skill

Convert markdown content to an e-ink optimized PDF and upload it to your Remarkable tablet's Inbox folder via the cloud API.

## Instructions

When the user invokes `/remarkable`, follow these steps:

### 1. Determine Input

The user may provide:
- **A file path** - e.g., `/remarkable ~/notes/meeting.md`
- **A file path with custom name** - e.g., `/remarkable ~/notes/meeting.md "Weekly Summary"`
- **Inline markdown** - They'll paste or type markdown content after invoking

If no input is provided, ask what markdown they want to convert.

### 2. Prepare the Markdown

If given a file path:
- Read the file to verify it exists
- Use the filename (without .md) as the default document name

If given inline content:
- Ask for a document name if not provided
- Write the content to a temp file at `/tmp/remarkable-input.md`

### 3. Convert and Upload

Run the conversion script:

```bash
~/.claude/skills/remarkable/scripts/remarkable-push.sh "<input-file>" "<document-name>"
```

### 4. Report Result

On success, confirm: "Uploaded **{name}.pdf** to Remarkable Inbox"

On failure, report the error and suggest troubleshooting:
- If rmapi fails with `cannot parse rootIndex, wrong schema got 4, expected: 3`: the
  rmapi binary is too old for reMarkable's current cloud. Install rmapi >= v0.0.34
  (see Dependencies) - the script prefers `~/.local/bin/rmapi` over the one on PATH.
- If rmapi fails with an auth error: re-authenticate by running `~/.local/bin/rmapi`
  and following the device registration flow.
- If pandoc/weasyprint fails: check the markdown syntax

## Dependencies

The user must have installed:
- `rmapi` **>= v0.0.34** (the maintained ddvk fork) at `~/.local/bin/rmapi`. reMarkable's
  cloud migrated to sync schema v4; older builds (including Homebrew's io41/tap/rmapi
  v0.0.29) can't parse it. Get the binary from
  https://github.com/ddvk/rmapi/releases (download `rmapi-macos-arm64.zip`, unzip,
  `chmod +x rmapi`, move to `~/.local/bin/rmapi`) or build from source
  (`git clone https://github.com/ddvk/rmapi && cd rmapi && go build -o ~/.local/bin/rmapi .`).
- `pandoc` - `brew install pandoc`
- `weasyprint` - `pip install weasyprint`

And authenticated rmapi by running `~/.local/bin/rmapi` once and following the device
registration flow. Auth is stored at `~/Library/Application Support/rmapi/rmapi.conf` on macOS.

## Examples

```
/remarkable
> What markdown do you want to send to your Remarkable?
> [user pastes content]
> What should I name this document?
> "Meeting Notes"
Uploaded Meeting Notes.pdf to Remarkable Inbox

/remarkable ~/docs/article.md
Uploaded article.pdf to Remarkable Inbox

/remarkable ~/docs/draft.md "Final Report"
Uploaded Final Report.pdf to Remarkable Inbox
```
