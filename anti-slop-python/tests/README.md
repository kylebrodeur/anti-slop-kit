# Tests

Fixtures that exercise every evidence rule, plus the commands to verify them.

## Evidence rules (ast-grep lane)

```bash
ast-grep scan --config ast-grep/sgconfig.yml --json tests/fixtures/evidence_rules.py \
  | python3 ast-grep/filter_safety.py
```

`tests/fixtures/evidence_rules.py` marks each violation with `# BAD:` and each
passing case with `# GOOD:`. Expect six findings, on exactly the five lines
carrying a `# BAD:` marker (line 42 is flagged by two rules):

- `no-any` (line ~13)
- `no-string-attribute-access` (line ~32)
- `require-safety-comment` (lines ~28, ~42)
- `no-module-mocking` (line ~38)
- `no-blanket-ignore` (line ~42: overlaps the bare ignore)

The GOOD cases, which must not appear: a concrete type, a cast with a `# SAFETY:`
on the preceding line, and a coded `# type: ignore[…]` with a `# SAFETY:`.

## Style lane (ruff)

```bash
ruff check --config config/ruff.toml <paths>
```

Covers ANN (annotations / `ANN401` Any), BLE/E722 (blind except), S110/S112
(silent swallow), TID251 (mock.patch), FBT (boolean traps), ARG (unused args),
C90/PLR09 (complexity), and the rest of the selected families.

## SAFETY exemption

`ast-grep` YAML cannot express "same or immediately preceding line", so
`require-safety-comment` and `no-any` always fire and `filter_safety.py` removes
the ones with an adjacent `# SAFETY:`. A comment separated by a blank line does
not count: matching the documented rule contract.
