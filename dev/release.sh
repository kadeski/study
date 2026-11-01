#!/usr/bin/env bash
# Builds the release branch from HEAD and pushes it. The release tree is HEAD's tree without
# the top-level entries listed in dev/not-shipped. The plugin directory and the kadeski
# marketplace read release, so their scans and installs see only the plugin. Run on main after
# the commit you want to release; it refuses a dirty tree and checks the result with the
# directory profile.
set -euo pipefail
cd "$(dirname "$0")/.."

DEV=$(tr '\n' ' ' < dev/not-shipped)

[ -z "$(git status --porcelain)" ] || { echo "FAIL: commit or stash your changes first"; exit 1; }
git fetch -q origin
parent=$(git rev-parse -q --verify refs/remotes/origin/release || true)

tree=$(git ls-tree HEAD | awk -F'\t' -v dev="$DEV" \
  'BEGIN { n = split(dev, a, " "); for (i = 1; i <= n; i++) skip[a[i]] = 1 } !($2 in skip)' | git mktree)
if [ -n "$parent" ] && [ "$(git rev-parse "$parent^{tree}")" = "$tree" ]; then
  echo "release already matches HEAD"; exit 0
fi

version=$(git show HEAD:.claude-plugin/plugin.json | jq -r .version)
commit=$(git commit-tree "$tree" ${parent:+-p "$parent"} -m "study $version from $(git rev-parse --short HEAD)")

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
git archive "$commit" | tar -x -C "$tmp"
claude plugin validate --profile directory "$tmp"

git update-ref refs/heads/release "$commit"
git push origin release
