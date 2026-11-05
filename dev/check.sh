#!/usr/bin/env bash
# Checks the plugin before a commit: the manifest, README, LICENSE and skills are well formed,
# nothing trips the plugin directory's known holds or blocks, the Python parses as 3.9 and its
# unit tests pass, and Claude Code validates the plugin. Warns when the plugin changed since
# origin/main but its version did not.
set -euo pipefail
cd "$(dirname "$0")/.."

for cmd in jq claude; do
  command -v "$cmd" >/dev/null || { echo "FAIL: $cmd is not on PATH"; exit 1; }
done

fail=0
err() { echo "FAIL: $*"; fail=1; }
warn() { echo "WARN: $*"; }

manifest=.claude-plugin/plugin.json
jq -e . "$manifest" >/dev/null || err "$manifest is missing or not valid JSON"
[ "$(jq -r .name "$manifest")" = study ] || err "$manifest: name is not study"
[ -f LICENSE ] || err "missing LICENSE"
words=$(sed '/^```/,/^```/d' README.md 2>/dev/null | wc -w)
[ "$words" -ge 40 ] || err "README.md missing or under 40 words"
[ -f .claude-plugin/icon.png ] || err "missing .claude-plugin/icon.png, the directory listing's icon"

for skill in skills/*/SKILL.md; do
  sdir=$(basename "$(dirname "$skill")")
  name=$(sed -n '2,/^---$/s/^name: *//p' "$skill")
  [ "$name" = "$sdir" ] || err "$skill: name '$name' does not match folder '$sdir'"
  sed -n '2,/^---$/p' "$skill" | grep -q '^description: ' || err "$skill: missing description"
done

# The whole repository is the plugin, so every tracked file ships and the directory checks it.
# It blocks system files and holds a version with a non-image file over 256 KiB or more than
# 512 files.
files=$(git ls-files -co --exclude-standard)
system=$(echo "$files" | grep -E '(^|/)(\.DS_Store|Thumbs\.db|desktop\.ini)$|(^|/)__MACOSX/' || true)
[ -z "$system" ] || err "system files the directory blocks: $(echo $system)"
[ "$(echo "$files" | wc -l)" -le 512 ] || err "more than 512 files"
for f in $files; do
  [ -e "$f" ] || continue  # tracked but deleted in the working tree
  case "$f" in *.png|*.jpg|*.jpeg|*.gif|*.webp) continue ;; esac
  [ "$(wc -c <"$f")" -le 262144 ] || err "$f is over 256 KiB"
done

# The directory holds a plugin with a credential-like name inside a ${...} substitution, even a
# JavaScript template literal (MCP_FORWARDS_CREDENTIAL_ENV). ${user_config.*} is allowed.
hits=$(git grep -n -o -i -E '\$\{[^}]*(key|token|secret|password|auth)[^}]*\}' | grep -v -i -F ':${user_config.' || true)
[ -z "$hits" ] || { err "credential-like name in a \${...} substitution, which the directory holds; rename it:"; echo "$hits"; }

# The Python must parse as 3.9, the oldest Study supports.
for f in $(echo "$files" | grep '\.py$'); do
  [ -e "$f" ] || continue
  python3 -c 'import ast, sys; ast.parse(open(sys.argv[1], encoding="utf-8").read(), feature_version=(3, 9))' "$f" 2>&1 \
    || err "$f does not parse as Python 3.9"
done
if ! out=$(python3 -m unittest discover -s tests 2>&1); then
  err "tests failed:"; echo "$out"
fi

# A change since this branch left origin/main needs a version bump to ship. Compares the working
# tree's tracked files with origin/main as last fetched.
if base=$(git merge-base HEAD origin/main 2>/dev/null); then
  version=$(jq -r .version "$manifest")
  if ! git diff --quiet "$base" -- . && [ "$(git show "$base:$manifest" | jq -r .version)" = "$version" ]; then
    warn "the plugin changed since origin/main but its version is still $version"
  fi
fi

# Validate what ships: the working tree without the top-level entries in dev/not-shipped,
# the same cut dev/release.sh makes.
ship=$(mktemp -d)
trap 'rm -rf "$ship"' EXIT
echo "$files" | grep -v -x -E "($(tr -d '\r' < dev/not-shipped | sed 's/[.]/\\./g' | paste -s -d '|' -))(/.*)?" | while read -r f; do
  [ -e "$f" ] && { mkdir -p "$ship/$(dirname "$f")"; cp "$f" "$ship/$f"; }
done
claude plugin validate "$ship" --strict || fail=1

[ "$fail" -eq 0 ] && echo "All checks passed."
exit "$fail"
