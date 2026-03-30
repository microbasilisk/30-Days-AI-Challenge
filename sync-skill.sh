#!/usr/bin/env bash
# sync-skill.sh — Pull a bff-skills PR into the 30-Days-AI-Challenge repo
#
# Usage:
#   ./sync-skill.sh <pr-number> <day-number> <skill-name> [category] [status]
#
# Examples:
#   ./sync-skill.sh 105 6 hodlmm-depth-scout "Yield" "Open"
#   ./sync-skill.sh 56 4 hermetica-yield-rotator "Yield" "Merged — Day 4 Winner"
#
# Requirements: gh (GitHub CLI), git, jq

set -euo pipefail

REPO="BitflowFinance/bff-skills"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# --- Args ---
PR_NUM="${1:?Usage: ./sync-skill.sh <pr-number> <day-number> <skill-name> [category] [status]}"
DAY_NUM="${2:?Missing day number}"
SKILL_NAME="${3:?Missing skill name}"
CATEGORY="${4:-Yield}"
STATUS="${5:-Open}"

DAY_DIR="$SCRIPT_DIR/day-${DAY_NUM}-${SKILL_NAME}"

echo "==> Fetching PR #${PR_NUM} from ${REPO}..."

# Fetch PR metadata
PR_JSON=$(gh pr view "$PR_NUM" --repo "$REPO" --json title,body,headRefName)
PR_TITLE=$(echo "$PR_JSON" | jq -r '.title')
PR_BODY=$(echo "$PR_JSON" | jq -r '.body')
PR_BRANCH=$(echo "$PR_JSON" | jq -r '.headRefName')

echo "    Title: $PR_TITLE"
echo "    Branch: $PR_BRANCH"

# --- Clone/update temp copy and fetch PR ref ---
TEMP_DIR="/tmp/bff-skills-sync"
if [ -d "$TEMP_DIR" ]; then
  cd "$TEMP_DIR"
  git fetch origin "pull/${PR_NUM}/head:pr-${PR_NUM}" --force 2>/dev/null || true
else
  git clone "https://github.com/${REPO}.git" "$TEMP_DIR" 2>/dev/null
  cd "$TEMP_DIR"
  git fetch origin "pull/${PR_NUM}/head:pr-${PR_NUM}" 2>/dev/null
fi

# Checkout PR branch
git checkout "pr-${PR_NUM}" 2>/dev/null

# --- Find and copy skill files ---
SKILL_SRC=""
if [ -d "skills/${SKILL_NAME}" ]; then
  SKILL_SRC="skills/${SKILL_NAME}"
elif [ -d "${SKILL_NAME}" ]; then
  SKILL_SRC="${SKILL_NAME}"
else
  # Search for the skill directory
  FOUND=$(find . -maxdepth 3 -type d -name "$SKILL_NAME" | head -1)
  if [ -n "$FOUND" ]; then
    SKILL_SRC="$FOUND"
  fi
fi

mkdir -p "$DAY_DIR"

if [ -n "$SKILL_SRC" ]; then
  echo "==> Copying skill files from ${SKILL_SRC}/"
  cp -r "${SKILL_SRC}/"* "$DAY_DIR/" 2>/dev/null || true
  # Count files copied
  FILE_COUNT=$(ls -1 "$DAY_DIR" | wc -l)
  echo "    Copied ${FILE_COUNT} files"
else
  echo "    WARNING: Could not find skill directory for '${SKILL_NAME}'"
  echo "    You may need to copy skill files manually"
fi

cd "$SCRIPT_DIR"

# --- Write README ---
echo "==> Writing README.md"
cat > "$DAY_DIR/README.md" <<READMEEOF
# Day ${DAY_NUM} — ${PR_TITLE}
> **Original PR:** https://github.com/${REPO}/pull/${PR_NUM}
> **Status:** ${STATUS}

${PR_BODY}
READMEEOF

# --- Update main README table ---
echo "==> Updating main README.md table"

# Check if this day/skill combo already exists in the table
if grep -q "day-${DAY_NUM}-${SKILL_NAME}" "$SCRIPT_DIR/README.md" 2>/dev/null; then
  echo "    Entry already exists in table — updating"
  # Build the new line
  NEW_LINE="| ${DAY_NUM} | [${PR_TITLE}](day-${DAY_NUM}-${SKILL_NAME}/) | ${CATEGORY} | ${STATUS} ([PR #${PR_NUM}](https://github.com/${REPO}/pull/${PR_NUM})) |"
  # Use a temp file for sed since macOS and GNU sed differ
  grep -v "day-${DAY_NUM}-${SKILL_NAME}" "$SCRIPT_DIR/README.md" > "$SCRIPT_DIR/README.md.tmp"
  # Find the table end and insert before it
  # Actually, just replace in-place with python for reliability
  python3 -c "
import re, sys
content = open('$SCRIPT_DIR/README.md').read()
# Find existing line with this day dir and replace it
pattern = r'\|[^\n]*day-${DAY_NUM}-${SKILL_NAME}[^\n]*\|'
new_line = '${NEW_LINE}'
content = re.sub(pattern, new_line, content)
open('$SCRIPT_DIR/README.md', 'w').write(content)
" 2>/dev/null || echo "    Could not auto-update existing entry — please update manually"
  rm -f "$SCRIPT_DIR/README.md.tmp"
else
  echo "    Adding new entry to table"
  NEW_LINE="| ${DAY_NUM} | [${PR_TITLE}](day-${DAY_NUM}-${SKILL_NAME}/) | ${CATEGORY} | ${STATUS} ([PR #${PR_NUM}](https://github.com/${REPO}/pull/${PR_NUM})) |"
  # Insert before the first blank line after the table header
  python3 -c "
import sys
lines = open('$SCRIPT_DIR/README.md').readlines()
new_line = '${NEW_LINE}\n'
# Find the table (after |-----|)
inserted = False
for i, line in enumerate(lines):
    if line.startswith('|-----'):
        # Find the end of the table
        j = i + 1
        while j < len(lines) and lines[j].startswith('|'):
            j += 1
        lines.insert(j, new_line)
        inserted = True
        break
if inserted:
    open('$SCRIPT_DIR/README.md', 'w').writelines(lines)
else:
    print('    Could not find table — please add entry manually')
"
fi

# --- Commit and push ---
echo "==> Committing and pushing"
cd "$SCRIPT_DIR"
git add -A
git commit -m "Add Day ${DAY_NUM}: ${PR_TITLE} (PR #${PR_NUM})" || { echo "Nothing to commit"; exit 0; }
git push

echo ""
echo "Done! Day ${DAY_NUM} — ${SKILL_NAME} synced from PR #${PR_NUM}"
echo "  Folder: day-${DAY_NUM}-${SKILL_NAME}/"
echo "  Repo:   https://github.com/cliqueengagements/30-Days-AI-Challenge"
