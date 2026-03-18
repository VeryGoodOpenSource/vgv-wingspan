#!/bin/bash
# Claude Code recommends keeping SKILL.md files under 500 lines
# to avoid degrading performance.
MAX_LINES=500
echo "Checking SKILL.md files for more than ${MAX_LINES} lines..."
oversized=0
while IFS= read -r file; do
  line_count=$(wc -l < "$file" | tr -d ' ')
  if [ "$line_count" -gt "$MAX_LINES" ]; then
    echo "::error file=$file::File has ${line_count} lines (limit: ${MAX_LINES}). Consider splitting the skill."
    oversized=$((oversized + 1))
  fi
done < <(find ./skills -name "SKILL.md" -not -path "./.git/*")

if [[ $oversized -gt 0 ]]; then
  echo "❌ $oversized SKILL.md file(s) exceed ${MAX_LINES} lines."
  exit 1
else
  echo "✅ All SKILL.md files are within line limits."
fi
