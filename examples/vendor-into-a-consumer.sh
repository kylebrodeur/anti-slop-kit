#!/usr/bin/env bash
# Run the vendored-into-a-consumer example end to end, in a throwaway dir.
#
# Usage: bash examples/vendor-into-a-consumer.sh
#
# It creates a consumer repo in a temp dir, vendors the policy into it,
# writes the lint config and a source file the policy objects to, and
# runs the lint. It prints what it does; it never writes outside the
# temp dir.
set -euo pipefail

KIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/anti-slop-example.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

echo "==> consumer repo: $WORK"
mkdir -p "$WORK/src"
cd "$WORK"

echo "==> writing the package.json (the lint config is ESM)"
cat > package.json <<'JSON'
{
  "name": "consumer",
  "version": "1.0.0",
  "type": "module",
  "private": true
}
JSON

echo "==> vendoring the TypeScript policy"
bash "$KIT_DIR/setup/install-anti-slop.sh"

echo "==> writing the lint config"
cat > oxlint.config.ts <<'TS'
import { defineConfig } from "oxlint";
export default defineConfig({
  jsPlugins: [{ name: "anti-slop", specifier: "./tools/oxlint/anti-slop/index.ts" }],
  rules: {
    "anti-slop/no-unknown-parameters": "error",
    "anti-slop/no-unsafe-dictionary-type": "error",
    "anti-slop/require-safety-comment-for-type-assertion": "error",
  },
});
TS

echo "==> writing source the policy objects to"
cat > src/thing.ts <<'TS'
export function pick(data: Record<string, unknown>, key: string) {
  return data[key] as string;
}
TS

echo "==> installing the dev deps"
npm install --silent -D oxlint@1.85.0 @oxlint/plugins@1.80.0

echo "==> running the policy (expect two findings)"
set +e
npx oxlint -c oxlint.config.ts src >lint-before.txt 2>&1
before_code=$?
set -e
grep -v 'MODULE_TYPELESS\|Reparsing\|To eliminate\|trace-warnings' lint-before.txt || true

# The example is only worth running if it actually asserts what it claims.
if [ "$before_code" -eq 0 ]; then
  echo "FAIL: the policy found nothing, but the source should trip two rules" >&2
  exit 1
fi
for rule in no-unsafe-dictionary-type require-safety-comment-for-type-assertion; do
  if ! grep -q "$rule" lint-before.txt; then
    echo "FAIL: expected finding '$rule' was not reported" >&2
    exit 1
  fi
done
echo "    ok: two expected findings, exit $before_code"

echo "==> fixing the source (expect no findings)"
cat > src/thing.ts <<'TS'
export function pick(data: Record<string, string>, key: string) {
  return data[key];
}
TS
set +e
npx oxlint -c oxlint.config.ts src >lint-after.txt 2>&1
after_code=$?
set -e
grep -v 'MODULE_TYPELESS\|Reparsing\|To eliminate\|trace-warnings' lint-after.txt || true

if [ "$after_code" -ne 0 ]; then
  echo "FAIL: the fixed source still fails the policy (exit $after_code)" >&2
  exit 1
fi
echo "    ok: no findings, exit 0"

echo "==> done"
