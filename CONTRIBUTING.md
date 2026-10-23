# Contributing

How to set up, verify, and open a change. Checked 2026-10-22.

## What this repo is

A vendored lint policy kit: the Oxlint plugin source (`anti-slop/`), the
Python policy (`anti-slop-python/`: ruff families, ast-grep evidence rules,
a SAFETY filter), two shell installers (`setup/`), and the guidance skills
(`skills/`). There is no pyproject, no package, no runtime: changes are
either policy source, installer, skill, or documentation.

## Set up

Clone, then check the two lint lanes and the installers are verifiable on
your machine:

```bash
git clone <this repo>
uv tool install ruff 2>/dev/null || true
npm --version
```

Verification uses: `ruff` (any recent version; the policy pins its own
families, not a ruff version), `ast-grep`, `node`/`npm` (for the
TypeScript rule sources), and `shellcheck` for the installers. Example
install:

```bash
uv tool install ruff
uv tool install --from ast-grep-cli ast-grep
cargo install ast-grep --locked 2>/dev/null || true
```

(The ast-grep and cargo lines are alternatives; one is enough.)

## Verify

**One command runs every gate, and it is the same script the CI runs:**

```bash
tests/run-tests.sh
```

It runs the ast-grep evidence lane (the shipped sources must scan clean,
the fixture must report exactly the `# BAD:` lines), the ruff style lane
(the fixture must report, or the config is enforcing nothing), and the
installer syntax and shellcheck pass. It needs `ruff`, `ast-grep` and
`shellcheck` on PATH; the script says which one is missing and how to
install it.

The individual gates, with what each one is expected to report, are
below. Run them directly when you want to see one of them on its own.

Run, from the repo root:

```bash
cd anti-slop-python && ast-grep scan --config ast-grep/sgconfig.yml --json \
  | python3 ast-grep/filter_safety.py
```

Expected: exit 0, no findings.

```bash
cd anti-slop-python && ast-grep scan --config ast-grep/sgconfig.yml --json \
  ast-grep/ config/ | python3 ast-grep/filter_safety.py
```

Expected: exit 0, no findings (the shipped rule sources must scan clean).

```bash
cd anti-slop-python && ast-grep scan --config ast-grep/sgconfig.yml --json \
  tests/fixtures/evidence_rules.py | python3 ast-grep/filter_safety.py
```

Expected: exit 1, with findings on exactly the fixture's `# BAD:` lines (13,
28, 32, 38, 42; line 42 is flagged by two rules) and never the `# GOOD:`
cases. See `anti-slop-python/tests/README.md` for the expected line list.

```bash
cd anti-slop-python && ruff check --config config/ruff.toml tests/fixtures/evidence_rules.py
```

Expected: exit 1 with findings on the fixture's `# BAD:` lines and the
fixture's own narration lines (14, 19, 36): `print` calls in a fixture file
(T201), a long line inside the file (E501 style), and the banned-api import
detection (TID251). A ruff version bump can shift the exact codes; the
invariant is that no finding may land on a `# GOOD:` case, and that the
evidence lane above reports findings on exactly the `# BAD:` lines.

```bash
bash -n setup/install-anti-slop.sh setup/install-anti-slop-python.sh
shellcheck -x setup/install-anti-slop.sh setup/install-anti-slop-python.sh
```

Expected: exit 0, no findings.

Documentation gates are enforced by the family verify harness (see the
runbook's verification gates section).

## Open a change

1. Branch from the default branch.
2. Make the change; state what it fixes, or that it is new policy.
3. Run the full set of verification commands above.
4. Include the evidence: a fixture exercising a new ast-grep rule in
   `anti-slop-python/tests/fixtures/`, or the command and its output for
   an installer change.
5. Open a pull request describing the change and why it belongs in the
   vendored source of truth rather than a consumer's local copy.

## Change rules

- `anti-slop/` (TypeScript) is upstream owned: do not hand-edit. Port an
  upstream change by re-copying the tree and updating the provenance date
  and the pinned Oxlint baseline in `setup/`.
- `anti-slop-python/` (Python) is synthesized here: port better rules from
  the source projects and record the lineage in `anti-slop-python/README.md`.
- Every new evidence rule ships with: the ast-grep YAML (or Oxlint rule
  source), a `# BAD:`/`# GOOD:` fixture, and a recipe line in the matching
  skill (`skills/anti-slop/SKILL.md`, `skills/anti-slop-python/SKILL.md`).
- Skills teach one boundary each; a rule that belongs in both languages'
  skills belongs as two entries, one per skill.
- Keep the prose gates: no banned filler words, no em or en dashes, no
  personal identifiers, in any markdown you add or touch.