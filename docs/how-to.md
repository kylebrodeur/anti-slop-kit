# How-to: anti-slop-tools

Day-to-day tasks, grouped by task. The commands in the first sections assume
you are in a consumer repo that has already vendored the policy; the last
section covers this kit itself. Checked 2026-10-22.

One question per task. The full command surface and every error string live in
the [runbook](RUNBOOK.md).

## When a finding appears, fix it at the code

Findings in owned source are the policy working. Read the rule id, apply its
recipe from the installed skill (`anti-slop` for TypeScript, `anti-slop-python`
for Python), and fix the code:

```bash
npm run lint:anti-slop
```

Each finding names its rule id (`anti-slop/no-unknown-returns`, for example)
and its message states the recipe. Apply the rule's recipe: parse at the I/O
boundary, declare the domain type, inject a real seam, never suppress. The
per-rule recipes are in the `anti-slop` skill and the runbook's fix index.

## First run on an existing repo: many findings

A repo adopted onto the policy reports a wall of findings first. Migrate
incrementally, per package, then land the rules at `error`. Do not suppress or
downgrade to make a first run pass.

## When a finding is genuinely unfixable: write a SAFETY line

For the Python evidence rules, a `# SAFETY:` comment on the finding line or the
one immediately above it suppresses exactly that finding:

```python
def promote(raw: object) -> User:
    # SAFETY: parse_user validates the payload is a User before this cast.
    return cast(User, raw)
```

For TypeScript type assertions the equivalent is
`// SAFETY: <why this holds>` (see the `anti-slop` skill). Prefer a named type
or `satisfies` so no assertion is needed at all.

## Update vendored policy in a consumer repo

Bump the vendored tree from this repo (upstream-owned for TypeScript; the
Python kit is adaptable). From the consumer repo, with the installed copy
already reviewed:

```bash
bash /path/to/anti-slop-tools/setup/install-anti-slop.sh tools/oxlint/anti-slop --force
bash /path/to/anti-slop-tools/setup/install-anti-slop-python.sh tools/anti-slop-python --force
```

Compare the diff against any locally adapted copy, then re-run the lanes.
Error strings for the guards are in the runbook.

## Verify the AST evidence lane when it stays quiet

ast-grep YAML cannot express "same or immediately preceding line", so the
Python evidence rules always fire and `filter_safety.py` removes the ones with
an adjacent `# SAFETY:`. A comment separated by a blank line does not count.
When the lane passes with findings you expected, confirm by running it against
the bundled fixture (see `anti-slop-python/tests/README.md`).

## This kit itself: fix the policy or the installers

Two things change here: the Python policy source (ruff families, ast-grep
rules, the SAFETY filter) and the two installers. See `docs/quickstart.md`
step 5 and the [runbook](RUNBOOK.md) verification gates for the exact
commands.

## What this is NOT

Not a runtime: nothing here intercepts your build, and there is no daemon.
Not an npm or PyPI dependency; the copy installed in a repo is the copy that
runs there. Policy questions belong to the skills, not to this document.