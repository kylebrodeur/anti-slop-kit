---
name: anti-slop-python
description: Use when editing Python in a repo that vendors the anti-slop-python policy, before adding Any, cast, type-ignore, getattr, or module mocks, when wiring the ruff and ast-grep lanes into a consumer repo, and when a ruff or ast-grep finding reports those on your change.
---

# anti-slop-python

Evidence-first Python linting: reject the low-evidence patterns coding agents
leave behind: `Any`, bare `cast`, unjustified `# type: ignore`, swallowed
exceptions, string-attribute access, module mocking. A type checker *permits*
all of these by construction; anti-slop bans the ones that launder evidence.

Three lanes, no overlap:

- **Ruff** owns style, correctness, imports, annotations (Python's
  `noImplicitAny`), complexity, blind-except, silent-swallow.
- **The type checker** (mypy / ty / pyright) owns types.
- **anti-slop** owns *evidence policy*: the gaps ruff cannot express, shipped
  as `ast-grep` rules plus a small `# SAFETY:` filter.

## The one hard rule for agents

**Never launder evidence to make lint pass.** Do NOT add `cast`, `# type: ignore`,
`getattr`, or `Any` to silence a finding; do not set a rule to `"off"` without a
written reason and an issue link; do not sprinkle suppressions. Fix the evidence:
**parse at the I/O boundary, declare the domain type, inject a real seam.** If a
finding genuinely cannot be fixed, leave it and say why.

## How to satisfy each rule

- **`anti-slop-python/no-any`**: explicit `Any` is no evidence. Replace it with
  the concrete domain type, or `# SAFETY: <reason>` on the same/preceding line.
- **`anti-slop-python/require-safety-comment`**: `cast(...)` and
  `# type: ignore[…]` destroy type evidence. State what you verified by hand in
  a `# SAFETY: <reason>` on the same or the immediately preceding line, or remove
  the hatch and name the type. A SAFETY separated by a blank line does not count.
- **`anti-slop-python/no-blanket-ignore`**: name the code: `# type: ignore[code]`,
  never a bare `# type: ignore`.
- **`anti-slop-python/no-string-attribute-access`**: `getattr`/`setattr`/
  `delattr`/`hasattr` bypass the checker. Access the typed attribute; if the name
  is genuinely dynamic, parse it into a bounded set of known fields at the boundary.
- **`anti-slop-python/no-module-mocking`**: `patch("dotted.path")` mocks state.
  Inject the collaborator through a real interface, service layer, or faithful
  test double. (Ruff `TID251` bans the same import.)
- **Ruff-backed**: `ANN401` (bans `Any` args), `BLE001`/`E722` (no blind/bare
  except), `S110`/`S112` (no silent pass/continue), `PGH003` (no blanket ignore),
  `TID251` (no `mock.patch`). Fix by naming the contract, not by suppressing.

Reach for: concrete domain types, `TypedDict`/dataclasses at boundaries,
`Protocol` seams, `typing.cast` only with a written SAFETY, and boundary parsing.

## Running it

```bash
uv run ruff check                      # style lane
ast-grep scan --config anti-slop-python/ast-grep/sgconfig.yml --json <paths> \
  | python3 anti-slop-python/ast-grep/filter_safety.py   # evidence lane
```

Exit 0 clean, 1 findings. Ruff owns the style/correctness rules; the ast-grep
lane adds the evidence gaps.

## Vendoring

anti-slop-python is **vendored, not depended upon**: the copy is meant to be
read and adapted. Run the installer from the source repo root:

```bash
bash /path/to/anti-slop-tools/setup/install-anti-slop-python.sh
```

It copies `anti-slop-python/` into the target repo (`tools/anti-slop-python/` by
default), merges the `[tool.ruff]` policy if none exists, and prints the
remaining wiring steps (pre-commit, CI, `ast-grep`/`ruff` dev-deps).

## Suppressing deliberately

A suppression is legitimate only where the rule's recipe does not apply, it names
the rule, and the reason is written next to it. Prefer a `# SAFETY:` justification
over a rule-level opt-out; record any `"off"` with a reason and an issue link.
