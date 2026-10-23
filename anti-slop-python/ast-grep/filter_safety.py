#!/usr/bin/env python3
"""Apply the `# SAFETY:` exemption to anti-slop AST findings.

ast-grep YAML cannot express "the same or the immediately preceding line", so
`anti-slop-python/require-safety-comment` and `.../no-any` are emitted for
every escape hatch and filtered here. Reads ast-grep JSON on stdin, writes the
surviving findings, exits 1 if any remain.

Usage:
    ast-grep scan --config sgconfig.yml --json <paths> | python filter_safety.py
"""

from __future__ import annotations

import json
import re
import sys

# Findings these rules suppress when a SAFETY line is adjacent.
SAFETY_SUPPRESSIBLE = {
    "anti-slop-python/require-safety-comment",
    "anti-slop-python/no-any",
}

SAFETY = re.compile(r"#\s*SAFETY\s*:")


def _has_safety(lines: list[str], line_number: int) -> bool:
    """True when the finding line or the immediately preceding line has SAFETY."""
    index = line_number - 1
    for candidate in (index, index - 1):
        if 0 <= candidate < len(lines) and SAFETY.search(lines[candidate]):
            return True
    return False


def _kept_findings(findings: list[dict]) -> list[dict]:
    cache: dict[str, list[str]] = {}
    kept: list[dict] = []
    for finding in findings:
        rule_id = finding.get("ruleId", "")
        if rule_id not in SAFETY_SUPPRESSIBLE:
            kept.append(finding)
            continue
        path = (finding.get("file") or "").strip()
        if path not in cache:
            try:
                with open(path, encoding="utf-8") as handle:
                    cache[path] = handle.read().splitlines()
            except OSError:
                cache[path] = []
        start = finding.get("range", {}).get("start", {})
        line_number = int(start.get("line", 0)) + 1  # ast-grep lines are 0-based
        if not _has_safety(cache[path], line_number):
            kept.append(finding)
    return kept


def main() -> int:
    raw = sys.stdin.read().strip()
    if not raw:
        return 0
    findings = json.loads(raw)
    kept = _kept_findings(findings)
    for finding in kept:
        rule_id = finding.get("ruleId", "anti-slop")
        message = finding.get("message", "")
        file = finding.get("file", "")
        start = finding.get("range", {}).get("start", {})
        line = int(start.get("line", 0)) + 1
        column = int(start.get("column", 0)) + 1
        print(f"{file}:{line}:{column}: {rule_id}: {message}", file=sys.stderr)
    if kept:
        print(f"anti-slop: {len(kept)} finding(s) after SAFETY filtering", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
