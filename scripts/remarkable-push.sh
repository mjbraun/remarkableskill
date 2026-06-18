#!/bin/bash
# ABOUTME: Converts markdown to e-ink optimized PDF and uploads to Remarkable tablet
# ABOUTME: Supports mermaid diagrams - renders them to PNG before PDF conversion

set -e

INPUT="$1"
NAME="${2:-$(basename "$INPUT" .md)}"
OUTPUT="/tmp/${NAME}.pdf"
CSS="$HOME/.claude/skills/remarkable/remarkable.css"
WORK_DIR="/tmp/remarkable-work-$$"

# reMarkable's cloud uses sync schema v4 (sync 1.5 / API v4), which needs
# rmapi >= v0.0.34. The Homebrew io41/tap/rmapi (v0.0.29) predates it and
# fails with "cannot parse rootIndex, wrong schema got 4, expected: 3".
# Prefer a known-good binary at ~/.local/bin/rmapi, then fall back to PATH.
if [[ -x "$HOME/.local/bin/rmapi" ]]; then
  RMAPI="$HOME/.local/bin/rmapi"
else
  RMAPI="rmapi"
fi

if [[ -z "$INPUT" ]]; then
  echo "Usage: remarkable-push.sh <input.md> [output-name]" >&2
  exit 1
fi

if [[ ! -f "$INPUT" ]]; then
  echo "Error: Input file not found: $INPUT" >&2
  exit 1
fi

# Create work directory
mkdir -p "$WORK_DIR"
trap "rm -rf $WORK_DIR" EXIT

# Copy input to work dir
cp "$INPUT" "$WORK_DIR/input.md"

# Check if file contains mermaid blocks
if grep -q '```mermaid' "$WORK_DIR/input.md"; then
  echo "Processing mermaid diagrams..."

  # Extract and render each mermaid block
  DIAGRAM_NUM=0
  TEMP_MD="$WORK_DIR/processed.md"

  # Use awk to process the file
  awk -v work_dir="$WORK_DIR" '
    BEGIN { in_mermaid = 0; diagram_num = 0 }
    /^```mermaid/ {
      in_mermaid = 1
      diagram_num++
      mermaid_file = work_dir "/diagram-" diagram_num ".mmd"
      next
    }
    /^```$/ && in_mermaid {
      in_mermaid = 0
      close(mermaid_file)
      print "![Diagram " diagram_num "](" work_dir "/diagram-" diagram_num ".png)"
      next
    }
    in_mermaid {
      print >> mermaid_file
      next
    }
    { print }
  ' "$WORK_DIR/input.md" > "$TEMP_MD"

  # Render each mermaid file to PNG
  for mmd_file in "$WORK_DIR"/diagram-*.mmd; do
    if [[ -f "$mmd_file" ]]; then
      png_file="${mmd_file%.mmd}.png"
      echo "  Rendering $(basename "$mmd_file")..."
      mmdc -i "$mmd_file" -o "$png_file" -b white -t neutral -w 800 2>/dev/null || {
        echo "Warning: Failed to render $mmd_file, using placeholder"
        # Create a simple placeholder
        echo "[Diagram rendering failed]" > "${mmd_file%.mmd}.txt"
      }
    fi
  done

  INPUT_FILE="$TEMP_MD"
else
  INPUT_FILE="$WORK_DIR/input.md"
fi

echo "Converting $INPUT to PDF..."
pandoc "$INPUT_FILE" -o "$OUTPUT" \
  --pdf-engine=weasyprint \
  --css="$CSS"

echo "Uploading to Remarkable..."
"$RMAPI" put "$OUTPUT" /Inbox/

rm -f "$OUTPUT"
echo "Uploaded: ${NAME}.pdf to /Inbox/"
