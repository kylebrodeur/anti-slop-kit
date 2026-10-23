---
name: anti-slop
description: Use whenever writing or editing TypeScript in a repo that vendors the anti-slop Oxlint plugin, before adding type assertions, unknown params/returns, Record maps, runtime typeof narrowing, module mocks, or oversized comments, and when lint:anti-slop or oxlint reports anti-slop findings on your change.
---

# anti-slop

Repos that vendor [`anti-slop`](https://github.com/dmmulroy/anti-slop) run Oxlint rules
that reject **low-evidence** TypeScript: code that launders types instead of proving them.
The plugin is vendored (not an npm dependency) at `tools/oxlint/anti-slop/` and wired
through the repo's `oxlint.config.ts`, usually as an `anti-slop` plugin group (plus an
optional repo-owned group for local rules).

Run it: `npm run lint:anti-slop` (or `oxlint -c oxlint.config.ts src` where an ESLint
`lint` already exists).

## The one hard rule for agents

**Never launder types to make lint pass.** Do NOT suppress rules, downgrade severity, add
`as any` / `as unknown as`, or delete a comment's meaning to silence a finding. Fix the code
so the evidence is real. If you genuinely cannot, leave the finding and say why.

## How to satisfy each rule

- **`no-unknown-parameters` / `no-unknown-returns` / `no-unknown-type-aliases`**: don't
  accept or return `unknown`. Parse at the I/O boundary (Zod is available in most repos)
  into a named domain type, then pass that. The one allowed `unknown` is a `cause` on an
  error.
- **`no-unsafe-dictionary-type`**: no `Record<string, unknown>` / `{ [k: string]: any }`.
  Give the map a concrete value type derived from a schema or owner contract.
- **`no-runtime-typeof`**: don't branch on ad-hoc `typeof x === "string"`. Parse the value
  at its boundary, then branch on the domain value. (Type guards/predicates are the
  exception.)
- **`no-chained-type-assertions` / `no-widen-then-assert`**: don't `x as object as T` or
  widen to `unknown` then assert back. Keep the precise type, or parse untrusted input.
- **`require-safety-comment-for-type-assertion`**: every non-`const` assertion needs a
  `// SAFETY: <why this holds>` on the line/statement before it. Prefer `satisfies` or a
  named type so no assertion is needed at all.
- **`no-known-value-widening`**: don't annotate a broad type that discards known keys
  (`const h: Record<string, Handler> = {...}`). Keep inference or use `satisfies`.
- **`no-object-parameters`**: no bare `object` param type; name the shape.
- **`no-conditional-empty-object-spread`**: no `...(cond ? { x } : {})`. Build the object
  and assign the property in a statement when present.
- **`no-module-mocking`**: no `vi.mock` / `jest.mock`. Inject real dependency seams instead.
- **`no-reflect-apply` / `no-reflect-get`**: call functions and read properties directly
  with their types; don't route through `Reflect`.
- **`no-shape-in-symbol-names`**: no case-insensitive substring "shape" in any JS/TS,
  private, or JSX symbol name (`FooShape` → rename for its domain role). "shape" describes
  structure rather than ownership; name the concept.

Reach for: inference, `as const`, `satisfies`, named owner contracts, and boundary parsing.

## Repo-owned rule: comment block size

Some repos add their own Oxlint group (e.g. a project-namespaced plugin) carrying a
`no-oversized-comments` rule that flags comment blocks over a small `maxLines` (commonly 4).
Large comment blocks that narrate obvious code are low-signal noise: prefer self-documenting
code with clear names and small functions.

This does **not** mean "don't document". Allowed:

- **`/** ... *\/` JSDoc**: documenting an API is always fine, any length.
- **Genuinely hard logic**: keep the explanation, but prefix it with **`WHY:`** so the
  intent is explicit and greppable (same pattern as `SAFETY:`). Comments are for the hard
  *why*, not the obvious *what*.
- License/banner and tooling directives (`eslint`, `oxlint`, `@ts-`, etc.).

Before writing a multi-line comment, ask: can a better name or smaller function remove the
need? If the code is genuinely hard and cannot be simplified, mark the comment `WHY:`.

## First-run findings

A repo adopted onto these rules reports many findings at first: expected, not a blocker.
Migrate incrementally per package and land the rules at `error`. Never suppress rules or add
casts to make a first run pass.
