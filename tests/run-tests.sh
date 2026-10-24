#!/usr/bin/env bash
# The local gate: everything the CI workflow runs, in the same order.
#
# The workflow has five steps, and until this script existed there was no
# single command that ran them. A contributor could not reproduce CI
# with one line, so a failure only showed up after it landed.
#
# Usage: tests/run-tests.sh
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${REPO_DIR}"

need() {
	command -v "$1" >/dev/null 2>&1 || {
		echo "missing: $1" >&2
		echo "  ruff:       uv tool install ruff" >&2
		echo "  ast-grep:   uv tool install ast-grep-cli" >&2
		echo "  shellcheck: brew install shellcheck" >&2
		exit 1
	}
}
need ruff
need ast-grep
need shellcheck

# The ast-grep steps run in the anti-slop-python directory, because that
# is where sgconfig.yml and filter_safety.py live. The CI says so with a
# per-step working-directory; the script says so with a cd.
PY_DIR="${REPO_DIR}/anti-slop-python"

echo "==> the ast-grep evidence lane: the shipped rule sources scan clean"
# ast-grep writes "[]" when nothing matches: treat that as clean.
# A TOOL FAILURE must not look like "clean", so the scan runs first and
# its output is parsed only after it succeeds.
set +e
out="$(cd "${PY_DIR}" && ast-grep scan --config ast-grep/sgconfig.yml --json ast-grep/ config/)"
code=$?
set -e
test "$code" -eq 0 || {
	echo "ast-grep failed on the shipped sources (exit $code); the tool must run for this gate to mean anything." >&2
	exit 1
}
n="$(printf '%s' "$out" | python3 -c 'import json,sys; print(len(json.load(sys.stdin)))')"
echo "    findings in shipped sources: $n"
test "$n" = "0" || {
	echo "The shipped rule sources must scan clean; see the fixture gate for expected findings." >&2
	exit 1
}

echo "==> the ast-grep evidence lane: the fixture hits exactly the BAD markers"
# The fixture is EXPECTED to produce findings, so ast-grep exits nonzero.
# Every error-tolerant command runs while `set -e` is OFF: re-enabling it
# before the assignments would abort on the nonzero scan, before the
# lines are ever parsed.
set +e
out="$(cd "${PY_DIR}" && ast-grep scan --config ast-grep/sgconfig.yml --json tests/fixtures/evidence_rules.py)"
code=$?
lines="$(printf '%s' "$out" | (cd "${PY_DIR}" && python3 ast-grep/filter_safety.py) 2>&1 | grep -Eo ':[0-9]+:[0-9]+:' | cut -d: -f2 | sort -nu | tr '\n' ' ')"
set -e
test "$code" -ne 0 || {
	echo "The fixture must REPORT findings (ast-grep exit 0 means nothing matched)." >&2
	exit 1
}
echo "    finding lines: $lines"
# 13, 28, 32, 38, 42: the five # BAD statements (42 is flagged by two rules)
test "$lines" = "13 28 32 38 42 " || {
	echo "Fixture did not report exactly the # BAD lines (13, 28, 32, 38, 42)." >&2
	exit 1
}

echo "==> the ruff style lane: the fixture reports the # BAD lines"
# The fixture is a NEGATIVE fixture, and its findings are the POINT.
#
# `tests/fixtures/evidence_rules.py` is a file of deliberately bad
# code, each bad line marked with a `# BAD:` comment. The gate runs
# ruff over it and REQUIRES exit 1 with the findings on exactly the
# `# BAD` lines. A clean pass means the config is not enforcing
# anything, so a clean pass is a FAILURE here.
#
# So the findings this prints are not lint debt and are not to be
# "fixed": fixing them would break the gate. The shipped rule sources
# are linted separately, and a finding there IS debt.
set +e
(cd "${PY_DIR}" && ruff check --config config/ruff.toml tests/fixtures/evidence_rules.py)
code=$?
set -e
# The fixture must REPORT (exit 1, findings only on the # BAD lines);
# a clean pass means the config is not enforcing anything.
test "$code" -eq 1 || {
	echo "ruff exit was $code, expected 1 (findings on the # BAD lines)." >&2
	exit 1
}

echo "==> the installers: shell syntax and shellcheck"
bash -n setup/install-anti-slop.sh setup/install-anti-slop-python.sh
shellcheck -x setup/install-anti-slop.sh setup/install-anti-slop-python.sh

echo "==> all gates passed"
