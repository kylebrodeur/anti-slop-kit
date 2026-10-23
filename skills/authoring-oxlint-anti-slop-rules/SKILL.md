---
name: authoring-oxlint-anti-slop-rules
description: Use when writing or adapting a new Oxlint evidence rule for TypeScript, whether in the anti-slop plugin source, a repo-owned plugin group, or when porting one of the source projects' rules into this kit.
---

# authoring-oxlint-anti-slop-rules

Rule-writing for the TypeScript lane. One rule, one evidence gap: a rule is
worth adding when a pattern hides whether the type evidence is real, not when
it is merely unusual style.

- Design in a rule's file under `anti-slop/rules/` (or the repo-owned plugin
  source for a consumer's own group). One exported rule per file; keep the
  file name and the rule id's suffix identical.
- Shared matchers live in `anti-slop/shared/`. Reuse them rather than
  repeating a pattern; a matcher duplicated across rules drifts.
- Every rule ships a diagnostic message that states the fix, not only the
  defect: parse at the boundary, name the domain type, or add
  `// SAFETY: <why this holds>`.
- Exceptions (type guards, JSDoc, directives) are part of the rule, not
  afterthoughts; encode them in the rule or its filter, never in prose alone.
- Rules added to `anti-slop/rules/` become part of the vendored, generic
  surface: keep them product neutral, one hard rule per concept, and register
  the id in the config sample in `anti-slop/README.md`.
- Consumer-specific policy belongs in the consumer's own plugin group, never
  in the generic vendored copy.
- Verify: compile the rule source standalone under the pinned baseline (see
  `docs/RUNBOOK.md`), then run the lane against a small fixture with the
  violating and the passing form; the first must report, the second must not.

This skill does not cover the Python lane; the ast-grep evidence rules have
their own authoring boundary in `skills/anti-slop-python/SKILL.md`, and the
UI-fragment rule family is a separate skill elsewhere.