#!/usr/bin/env bash
# install-anti-slop-python.sh
# Vendors the neutral anti-slop-python policy + skill into a Python project.
# anti-slop-python is vendored, not depended upon (see anti-slop-python/README.md).
#
# Run from the root of the project that should receive the policy:
#   bash /path/to/anti-slop-tools/setup/install-anti-slop-python.sh [dest-dir] [--force]
#
# dest-dir defaults to tools/anti-slop-python.
#
# Neutral by construction: generic evidence policy only — no product/vendor
# branding. The project's own ruff config always wins over the shipped default.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_SRC="$(dirname "$SCRIPT_DIR")"
POLICY_SRC="$REPO_SRC/anti-slop-python"
SKILL_SRC="$REPO_SRC/skills/anti-slop-python/SKILL.md"
PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
SKILL_DEST="$PROJECT_ROOT/.claude/skills/anti-slop-python"

DEST="tools/anti-slop-python"
FORCE=0
for arg in "$@"; do
  case "$arg" in
    --force) FORCE=1 ;;
    *) DEST="$arg" ;;
  esac
done

if [[ ! -d "$POLICY_SRC" ]]; then
  echo "❌  No policy source at $POLICY_SRC — run this from anti-slop-tools/setup." >&2
  exit 1
fi

if [[ -e "$DEST" && "$FORCE" -ne 1 ]]; then
  echo "❌  $DEST already exists. Review the diff, then re-run with --force to overwrite." >&2
  exit 1
fi

echo "📦  Vendoring anti-slop-python -> $DEST"
mkdir -p "$DEST"
cp -R "$POLICY_SRC/." "$DEST/"

echo "🧠  Installing anti-slop-python skill -> $SKILL_DEST/SKILL.md"
mkdir -p "$SKILL_DEST"
cp "$SKILL_SRC" "$SKILL_DEST/SKILL.md"

if [[ -f "ruff.toml" || -f ".ruff.toml" ]] || grep -q "\[tool.ruff" pyproject.toml 2>/dev/null; then
  echo "ℹ️   Existing Ruff config found — NOT overwriting."
  echo "    Merge the [lint] table from $DEST/config/ruff.toml into your Ruff config."
  echo "    (Your config wins; the shipped default only fills gaps.)"
else
  echo "📋  No Ruff config found — copy $DEST/config/ruff.toml to the repo root."
fi

cat <<EOF

✅  Policy vendored. Remaining manual steps:
    1. dev deps:  uv add --dev ruff ast-grep-cli   # or pin versions in pyproject
    2. pre-commit: merge $DEST/pre-commit-fragment.yaml into .pre-commit-config.yaml
    3. CI: add the two lanes as a step:
         uv run ruff check
         ast-grep scan --config $DEST/ast-grep/sgconfig.yml --json \\
           | python3 $DEST/ast-grep/filter_safety.py
    4. (optional) ty strict config: $DEST/config/ty.toml

    Run it once; findings in owned source are expected on first run.
    Do NOT suppress rules or add casts just to make lint pass.
EOF
