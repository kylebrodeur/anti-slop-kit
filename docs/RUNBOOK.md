# RUNBOOK: anti-slop-tools

The operator's reference: the full command surface, every error string and its
fix, and the verification gates. Checked 2026-10-22.

## Command surface (complete)

Consumer-side commands, run in the consumer repo:

```bash
# Vendor the TypeScript plugin and its skill
bash /path/to/anti-slop-tools/setup/install-anti-slop.sh [dest-dir] [--force]

# Vendor the Python policy and its skill
bash /path/to/anti-slop-tools/setup/install-anti-slop-python.sh [dest-dir] [--force]

# TypeScript lint lane
npm run lint:anti-slop                       # or: oxlint -c oxlint.config.ts src

# Python lint lanes
uv run ruff check
ast-grep scan --config tools/anti-slop-python/ast-grep/sgconfig.yml --json \
  | python3 tools/anti-slop-python/ast-grep/filter_safety.py

# Types (optional strict config ships with the policy)
uv run ty check                              # config: tools/anti-slop-python/config/ty.toml
```

Kit-side verification commands, run in this repo (paths from
`anti-slop-tools/`):

```bash
# Python lane: zero findings expected from the shipped rule sources
# (scan the rule and config dirs; do not scan tests/ in this gate)
cd anti-slop-python && ast-grep scan --config ast-grep/sgconfig.yml --json \
  ast-grep/ config/ | python3 ast-grep/filter_safety.py

# Fixture: findings sit only on the fixture's # BAD lines (13, 28, 32, 38, 42)
cd anti-slop-python && ast-grep scan --config ast-grep/sgconfig.yml --json \
  tests/fixtures/evidence_rules.py | python3 ast-grep/filter_safety.py

# Ruff lane smoke check: it must report; findings sit on the fixture's
# # BAD and narration lines, never on a # GOOD case
cd anti-slop-python && ruff check --config config/ruff.toml tests/fixtures/evidence_rules.py

# Installer syntax and shell analysis
bash -n setup/install-anti-slop.sh setup/install-anti-slop-python.sh
shellcheck -x setup/install-anti-slop.sh setup/install-anti-slop-python.sh
```

## Installer guards and their fixes

- `❌  No plugin source at $PLUGIN_SRC: run this from anti-slop-tools/setup.`
  Fix: the installer resolves its source relative to its own location. Run it
  from the vendored checkout (`bash /path/to/anti-slop-tools/setup/install-anti-slop.sh`), not from a copy that lost the sibling `anti-slop/` directory.
- `❌  No policy source at $POLICY_SRC: run this from anti-slop-tools/setup.`
  Fix: same as above for the Python installer.
- `❌  $DEST already exists. Review the diff, then re-run with --force to overwrite.`
  Not an error: a guard against clobbering a locally adapted copy. Fix:
  compare the diff first, then re-run with `--force`.
- `ℹ️   Existing Oxlint config found: NOT overwriting.` Merge the listed
  entries (jsPlugins, the rule map, ignorePatterns) into the existing config; fix
  the merge, keep existing entries.
- `ℹ️   Existing Ruff config found: NOT overwriting.` Merge the `[lint]` table
  from `tools/anti-slop-python/config/ruff.toml`; your config wins.
- `📋  No Oxlint config found: write one wiring $DEST ...` The installer
  cannot generate your config; follow `anti-slop/README.md` for the config body.
- `📋  No Ruff config found: copy $DEST/config/ruff.toml to the repo root.`
  Fix: copy the shipped config, or merge into yours.

## Lint error strings and their fixes

Every finding message names its recipe. The rule map below is the fix index.

TypeScript (`anti-slop/*`), all Oxlint rules at `error`:

- `no-unknown-parameters` / `no-unknown-returns` / `no-unknown-type-aliases`
  Fix: parse at the I/O boundary into a named domain type. (Allowed: a `cause`
  on an error.)
- `no-unsafe-dictionary-type`. Fix: give the record a concrete value type from
  a schema or owner contract.
- `no-runtime-typeof`. Fix: parse the value at its boundary; type guards are
  the exception.
- `no-chained-type-assertions` / `no-widen-then-assert`. Fix: keep the precise
  type, or parse untrusted input.
- `require-safety-comment-for-type-assertion`. Fix: a `// SAFETY: <why this
  holds>` on the line before the non-`const` assertion, or remove the
  assertion with `satisfies` / a named type.
- `no-known-value-widening`. Fix: keep inference or use `satisfies`.
- `no-object-parameters`. Fix: name the shape.
- `no-conditional-empty-object-spread`. Fix: build the object, then assign the
  property in a statement when present.
- `no-module-mocking`. Fix: inject a real dependency seam; never `vi.mock` or
  `jest.mock`.
- `no-reflect-apply` / `no-reflect-get`. Fix: call and read directly with types.
- `no-shape-in-symbol-names`. Fix: rename for the domain role.

Python, ruff families (`ANN401`, `BLE001`, `E722`, `S110`, `S112`, `PGH003`,
`TID251`, and the rest of the selected list in
`anti-slop-python/config/README.md`). Fix by naming the contract, never by
suppressing. Note the ruff lane also carries style rules (correct imports,
line length): those are the style lane, fix them normally.

Python, ast-grep evidence rules (`anti-slop-python/*`), the gaps ruff cannot
express as evidence rules:

- `no-any`. Fix: the concrete domain type, or `# SAFETY: <reason>` on the same
  or the immediately preceding line.
- `require-safety-comment`. Fix: a `# SAFETY:` on the same or the immediately
  preceding line for `cast(...)` / `# type: ignore` / `# ty: ignore`, or name
  the type. A SAFETY separated by a blank line does not count.
- `no-blanket-ignore`. Fix: name the code (`# type: ignore[code]`).
- `no-string-attribute-access`. Fix: access the typed attribute; if the name is
  genuinely dynamic, parse it into a bounded set of known fields at the
  boundary.
- `no-module-mocking`. Fix: inject the collaborator through a real interface
  or service layer (ruff `TID251` bans the same import).

## Recovery procedures

- A first run reports a wall of findings: expected. Migrate incrementally per
  package, land rules at `error`, do not suppress to make a first run pass.
- The ast-grep lane exits 1 with `anti-slop: N finding(s) after SAFETY
  filtering` (stderr; stdout stays the JSON for piping): findings remain
  after the SAFETY filter. Fix each at the code or add a `# SAFETY:` on the
  adjacent line where genuinely justified.
- A vendored copy drifts from here or from upstream: re-run the installer with
  the same `--force` and review the diff; locally adapted rules must be moved
  into a repo-owned Oxlint plugin group, never into the vendored generic copy.
- Upstream changed the plugin: re-copy the whole tree into `anti-slop/` and
  record the provenance date in `anti-slop/README.md`; keep the pinned Oxlint
  baseline in both installers in lockstep with the refresh.

## Verification gates (this repo)

- gate 1: the ast-grep evidence lane over the shipped rule and config sources
  must be exit 0 with zero findings.
- gate 2: the fixture, when scanned, must flag only the `# BAD:` lines (13,
  28, 32, 38, 42, two rules on 42) and never the `# GOOD:` cases.
- gate 3: the ruff style smoke check on the fixture must report, with
  findings on the `# BAD:` lines and the fixture's narration lines (14, 19,
  36 are `print`, length, and banned-import style findings in the fixture
  file itself) and no finding on a `# GOOD:` case.
- gate 4: `bash -n` and `shellcheck -x` on both installers, with no findings.
- gate 5: documentation verification harness,
  the family harness (in the private control-plane repo) against this
  checkout, exit 0. Prose gates in this repo: no banned words or em/en dashes in any
  markdown, and no personal identifiers in any tracked document; see
  `.pre-commit-config.yaml` if present, and the harness output.

## Boundary

No daemon, no server mode, no auto-fixer for the evidence rules (the ruff lane
has `--fix` only). Not a test runner: nothing here runs pytest, and the repo
ships no test runner config; the fixture in `anti-slop-python/tests/` is
exercised by the lint lanes above. Not a policy consumer: it does not lint
itself against its own product rules, only against its verification gates
above.