# Quickstart: anti-slop-tools

The numbered path from nothing to a passing lint policy. This repo is a
vendored policy kit: its output is other repos passing lint, not something
that runs on its own. Copy-pasteable commands only. Checked 2026-10-22.

## Paths

- [README](../README.md) for the map and family links.
- [How-to](how-to.md) for the day-to-day tasks.
- [Runbook](RUNBOOK.md) for the full command surface and error fixes.

## 1. Vendor the TypeScript policy into a consumer repo

From the root of the consumer repo (run the installer by absolute path; the
consumer repo is the one that receives the policy):

```bash
bash /path/to/anti-slop-tools/setup/install-anti-slop.sh
```

Expected output when no Oxlint config exists:

```
📦  Vendoring anti-slop plugin -> tools/oxlint/anti-slop
🧠  Installing anti-slop guidance skill -> .claude/skills/anti-slop/SKILL.md

✅  Plugin vendored. Remaining manual steps:
    1. Install dev deps (keep versions in lockstep):
         npm add -D oxlint@1.85.0 @oxlint/plugins@1.80.0
    2. Add a script:  "lint:anti-slop": "oxlint -c oxlint.config.ts src"
    3. Add this repo's own rule group separately if it has local policy.
    4. Run it. Findings in owned source are expected on first run.
```

## 2. Wire and run the TypeScript lane

In the consumer repo, then lint its own source:

```bash
npm add -D oxlint@1.85.0 @oxlint/plugins@1.80.0
npm run lint:anti-slop
```

Expected on a repo that already satisfies the rules:

```
Found 0 warnings and 0 errors.
```

A first run on a previously unlinted repo reports findings. That is the
expected state, not a failure: migrate incrementally.

## 3. Vendor the Python policy

```bash
bash /path/to/anti-slop-tools/setup/install-anti-slop-python.sh
```

Expected output when no Ruff config exists:

```
📦  Vendoring anti-slop-python -> tools/anti-slop-python
🧠  Installing anti-slop-python skill -> .claude/skills/anti-slop-python/SKILL.md
📋  No Ruff config found: copy tools/anti-slop-python/config/ruff.toml to the repo root.

✅  Policy vendored. Remaining manual steps:
    1. dev deps:  uv add --dev ruff ast-grep-cli   # or pin versions in pyproject
    2. pre-commit: merge tools/anti-slop-python/pre-commit-fragment.yaml into .pre-commit-config.yaml
    3. CI: add the two lanes as a step:
         uv run ruff check
         ast-grep scan --config tools/anti-slop-python/ast-grep/sgconfig.yml --json \
           | python3 tools/anti-slop-python/ast-grep/filter_safety.py
```

## 4. Run the Python two-lane policy in the consumer

```bash
uv run ruff check
ast-grep scan --config tools/anti-slop-python/ast-grep/sgconfig.yml --json \
  | python3 tools/anti-slop-python/ast-grep/filter_safety.py
```

Expected when the lanes pass: ruff prints `All checks passed!` and the ast-grep
lane prints its findings (if any) on stderr with a count line, exits 0 when
none remain. Error strings and their fixes are in the runbook.

## 5. Verify the policy kit itself, in this repo

The kit self-verifies with the same two lanes plus shell analysis, from the
repo root:

```bash
cd anti-slop-python && ast-grep scan --config ast-grep/sgconfig.yml --json \
  ast-grep/ config/ | python3 ast-grep/filter_safety.py
```

Expected: exit 0 with zero findings from the shipped rule sources. Then the
fixture gate (findings sit only on the fixture's `# BAD:` lines:
`anti-slop-python/tests/README.md`) and the shell gates (`bash -n` and
`shellcheck -x` on both installers, no findings). The ruff smoke check on the
fixture must report, with no finding on a `# GOOD:` case. Full commands:
[docs/RUNBOOK.md](RUNBOOK.md).

## What this is NOT

Not a CLI, not an npm package, not an installable Python package: there is no
`pyproject.toml`, no test runner to invoke, nothing to `npx`. The deliverable
is vendored policy plus its skills. If you expected `python -m anti_slop` or
`npx anti-slop`, the runbook's install section is the real path.