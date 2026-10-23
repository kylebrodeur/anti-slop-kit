# anti-slop-python: neutral source of truth

Opinionated, **evidence-first** linting for Python: reject the low-evidence,
low-signal patterns coding agents leave behind: `Any`, bare `cast`,
unjustified `# type: ignore`, swallowed exceptions, string-attribute access,
module mocking, `isinstance` ladders. A type checker *permits* all of these by
construction; anti-slop bans the ones that launder evidence, and every finding
says what to write instead.

This directory is a **product-neutral** policy, intended to be vendored into
other repos. It carries **only** generic Python rules: no project or vendor
branding.

## Lineage

Synthesized from the strongest Python ports of
[dmmulroy/anti-slop](https://github.com/dmmulroy/anti-slop) (the canonical
Oxlint ruleset this ecosystem already runs for TypeScript):

| Contributed | Source |
|---|---|
| Reasoned ruff rule-family selection (`docs/config/ruff.md`) | [`zkewal/pyslop`](https://github.com/zkewal/pyslop) |
| 15-rule catalog, `# SAFETY:` convention, agents-first diagnostics, `review`/presets/baseline | [`TinyFrontier/anti-slop-py`](https://github.com/TinyFrontier/anti-slop-py) |
| Ruff `--extend-select` policy + banned-API table, `no-any-containers`, module-size limits | [`ruarfff/anti-slop-python`](https://github.com/ruarfff/anti-slop-python) |

## Layering (three lanes, no overlap)

- **Ruff** carries everything it already has: style, correctness, imports, the
  annotation rules that are Python's `noImplicitAny`, complexity caps, blind-except,
  bandit silent-swallow, unused-args, PGH blanket-ignore.
- **A type checker** (mypy / ty / pyright) owns types.
- **anti-slop** owns *evidence policy*: the four gaps ruff cannot express as
  evidence rules, shipped here as `ast-grep` rules.

## Files

```
config/ruff.toml        ruff [lint] select/ignore policy (the reasoned families)
config/ty.toml          optional strict type-checker config (ty)
ast-grep/sgconfig.yml   ast-grep config pointing at the rule dir
ast-grep/rules/         the evidence rules ruff cannot express
pre-commit-fragment.yaml  drop-in pre-commit hook block
```

See `../skills/anti-slop-python/SKILL.md` for the vendor-and-configure procedure
and `config/README.md` for the rationale behind each ruff family.

## Rules: the evidence gaps (ast-grep)

| Rule id | Flags |
|---|---|
| `anti-slop-python/no-any` | explicit `Any` annotation without `# SAFETY:` |
| `anti-slop-python/require-safety-comment` | `cast(...)` / `# type: ignore` / `# ty: ignore` without `# SAFETY:` |
| `anti-slop-python/no-blanket-ignore` | bare `# type: ignore` with no error code |
| `anti-slop-python/no-string-attribute-access` | `getattr`/`setattr`/`delattr`/`hasattr` with a string-literal name |
| `anti-slop-python/no-module-mocking` | `patch("dotted.path")` / `monkeypatch.setattr("dotted.path", …)` |

The ruff policy covers the rest (`ANN401` for `Any` params, `TID251` for
`mock.patch`, `BLE001`/`E722`/`S110`/`S112` for swallowed exceptions, etc.).

## Do not launder evidence to pass

Never add `cast`, `# type: ignore`, `getattr`, or `Any` to silence a finding,
and never set a rule to `"off"` without a written reason and an issue link.
Fix the evidence: parse at the I/O boundary, declare the domain type, inject a
real seam.

## Updating

These rules are synthesized, not upstream-owned: adapt them to the team's
standards. When a source port ships a better rule, port it into
`ast-grep/rules/` and record the change here.
