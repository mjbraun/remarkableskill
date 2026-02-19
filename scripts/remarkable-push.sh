#!/bin/bash
# ABOUTME: Converts markdown to e-ink optimized PDF and uploads to Remarkable tablet
# ABOUTME: Usage: remarkable-push.sh <input.md> [output-name]

set -e

INPUT="$1"
NAME="${2:-$(basename "$INPUT" .md)}"
OUTPUT="/tmp/${NAME}.pdf"
CSS="$HOME/.claude/skills/remarkable/remarkable.css"

if [[ -z "$INPUT" ]]; then
  echo "Usage: remarkable-push.sh <input.md> [output-name]" >&2
  exit 1
fi

if [[ ! -f "$INPUT" ]]; then
  echo "Error: Input file not found: $INPUT" >&2
  exit 1
fi

echo "Converting $INPUT to PDF..."
pandoc "$INPUT" -o "$OUTPUT" \
  --pdf-engine=weasyprint \
  --css="$CSS"

echo "Uploading to Remarkable..."
rmapi put "$OUTPUT" /Inbox/

rm -f "$OUTPUT"
echo "Uploaded: ${NAME}.pdf to /Inbox/"
