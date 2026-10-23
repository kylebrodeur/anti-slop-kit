#!/usr/bin/env bash
# install-anti-slop.sh
# Vendors the neutral anti-slop Oxlint plugin + guidance skill into a project.
# anti-slop is vendored, not an npm dependency (see anti-slop/README.md).
#
# Run from the root of the project that should receive the plugin:
#   bash /path/to/anti-slop-tools/setup/install-anti-slop.sh [dest-dir] [--force]
#
# dest-dir defaults to tools/oxlint/anti-slop (pass another relative path when
# the repo has an established tooling layout).
#
# Neutral by construction: only the generic anti-slop/* rules are copied — no
# product groups or branding. Consumers add their own owned group separately.

set -euo pipefail

# Oxlint baseline — keep both packages in lockstep. Bump here when the plugin
# source is refreshed from upstream (see anti-slop/README.md).
OXLINT_VERSION="1.85.0"
PLUGINS_VERSION="1.80.0"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_SRC="$(dirname "$SCRIPT_DIR")"
PLUGIN_SRC="$REPO_SRC/anti-slop"
SKILL_SRC="$REPO_SRC/skills/anti-slop/SKILL.md"
PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
SKILL_DEST="$PROJECT_ROOT/.claude/skills/anti-slop"

DEST="tools/oxlint/anti-slop"
FORCE=0
for arg in "$@"; do
  case "$arg" in
    --force) FORCE=1 ;;
    *) DEST="$arg" ;;
  esac
done

if [[ ! -f "$PLUGIN_SRC/index.ts" ]]; then
  echo "❌  No plugin source at $PLUGIN_SRC — run this from anti-slop-tools/setup." >&2
  exit 1
fi

if [[ -e "$DEST" && "$FORCE" -ne 1 ]]; then
  echo "❌  $DEST already exists. Review the diff, then re-run with --force to overwrite." >&2
  echo "    (Compare against the source before clobbering a locally-adapted copy.)" >&2
  exit 1
fi

echo "📦  Vendoring anti-slop plugin -> $DEST"
mkdir -p "$DEST"
cp -R "$PLUGIN_SRC/." "$DEST/"
# The README documents provenance for the copied tree; keep it with the copy.
rm -f "$DEST/README.md" 2>/dev/null || true

if [[ -f "oxlint.config.ts" || -f ".oxlintrc.json" || -f "oxlint.config.js" ]]; then
  echo "ℹ️   Existing Oxlint config found — NOT overwriting."
  echo "    Merge these into it (keep your existing entries):"
  echo "      - jsPlugins: { name: \"anti-slop\", specifier: \"./$DEST/index.ts\" }"
  echo "      - all 15 anti-slop/* rules at \"error\" (see $PLUGIN_SRC/README.md)"
  echo "      - ignorePatterns: \"$DEST/**\" plus this repo's agent-tooling dirs"
else
  echo "📋  No Oxlint config found: write one wiring $DEST (see $PLUGIN_SRC/README.md)."
fi

echo "🧠  Installing anti-slop guidance skill -> $SKILL_DEST/SKILL.md"
mkdir -p "$SKILL_DEST"
cp "$SKILL_SRC" "$SKILL_DEST/SKILL.md"

echo
echo "✅  Plugin vendored. Remaining manual steps:"
echo "    1. Install dev deps (keep versions in lockstep):"
echo "         npm add -D oxlint@$OXLINT_VERSION @oxlint/plugins@$PLUGINS_VERSION"
echo "    2. Add a script:  \"lint:anti-slop\": \"oxlint -c oxlint.config.ts src\""
echo "    3. Add this repo's own rule group separately if it has local policy."
echo "    4. Run it. Findings in owned source are expected on first run."
echo
echo "    Do NOT suppress rules or add casts just to make lint pass."
