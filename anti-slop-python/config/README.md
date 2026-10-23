# Ruff family rationale

Why each ruff family is selected for evidence-first Python. Ruff carries what
it already has so the ast-grep rules beside this file only add the gaps.

## Selected

- **E, W** (pycodestyle errors/warnings): basic hygiene; keeps diffs clean so
  the evidence findings are visible.
- **F** (pyflakes): unused imports/names, undefined names. Dead code is where
  slop hides.
- **I** (isort): sorted imports; required for `--fix` to be deterministic.
- **UP** (pyupgrade): modern syntax for the floor version (`X | None`, `match`).
  Old idioms invite untyped patterns.
- **B** (flake8-bugbear): likely bugs: mutable defaults, unused loop vars.
- **ANN** (flake8-annotations): every param and return annotated. This is
  Python's `noImplicitAny`: TypeScript repos get it from the compiler, but Python
  has no checker default that requires it, so ruff carries it. An unannotated
  parameter is *no evidence*: the core of what anti-slop is about. Includes
  **ANN401** (bans `Any`); the `no-any` ast-grep rule independently requires
  SAFETY for explicit `Any`.
- **BLE** (flake8-blind-except): no blind `except Exception` / bare `except`.
- **TRY** (tryceratops) minus **TRY003**: `raise` without `from`, verbose
  logging in handlers. TRY003 (message style) is ignored; see below.
- **S110, S112** (flake8-bandit): `try/except/pass`, `try/except/continue`:
  silent swallowing. (Full `S` is off: bandit needs per-repo tuning.)
- **ERA** (eradicate): dead commented-out code.
- **ARG** (flake8-unused-arguments): unused function arguments, including
  `**kwargs` no one reads.
- **FBT** (flake8-boolean-trap): boolean positional args/traps in signatures.
- **PLR09** (pylint refactor): too many branches/returns/statements; long
  functions accumulate untyped shortcuts.
- **C90** (mccabe): complexity cap, same reason as PLR09.
- **RET** (flake8-return): redundant `else: return`, missing explicit return.
- **SIM** (flake8-simplify): `isinstance` nests and other simplifiable shapes
  that hide data contracts.
- **PERF** (perflint): list-building anti-patterns.
- **FURB** (refurb): modern idioms the type checker understands better.
- **PIE** (flake8-pie): miscellaneous correctness (`unnecessary-pass`, …).
- **PGH** (pygrep-hooks): **PGH003** bans blanket `# type: ignore` without a
  code; pairs with the SAFETY rule.
- **RUF** (ruff-specific): **RUF100** flags unused `noqa`, so suppressions
  cannot linger after the violation is gone.
- **T20** (flake8-print): no `print` in shipped code; use logging.
- **TD** (flake8-todo): `TODO`/`FIXME` stay visible as findings.
- **FIX** (flake8-fixme): same as TD for `FIXME`/`XXX`/`HACK`.

## Deliberately not selected

- **D** (pydocstyle): docstring presence and shape is a per-repo style rollout,
  not slop. Add it to `select` per repo if wanted.
- **TRY003**: exception-message length is style, not evidence; it dominates
  real adoptions with four-digit counts.

## Thresholds

`max-complexity = 10`, `max-statements = 40`: long functions are where untyped
shortcuts accumulate. Tune per repo with a recorded reason.
