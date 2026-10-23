---
name: authoring-shadcn-lint-rules
description: Use when writing lint rules that police UI component conventions (shadcn-style component structure: file placement, primitive wrapping, class merging, variant props) rather than the anti-slop evidence policy, and when adapting those framework-focused rules into a repo's own Oxlint plugin group.
---

# authoring-shadcn-lint-rules

Framework-focused rule authoring: these rules police conventions (where a
component lives, which primitives it wraps, how classes merge), not the
anti-slop evidence policy, and they belong in a consumer's owned Oxlint
group, never in the generic vendored copy.

- Every rule targets a convention the framework itself does not enforce; if
  the rule would matter in any codebase, it belongs in the anti-slop lane
  instead.
- One rule per convention; name the id after the component boundary it
  polices (`ui/button` conventions, primitive wrapping, class merge), with
  the consumer's group prefix.
- Diagnostics name the convention and its expected form, not just the
  violation.
- Keep the rule's exemption list explicit (variant props, forwarded refs, and
  the class-merge helper itself are usual cases).
- This skill does not cover the anti-slop evidence rules (both languages);
  those are `skills/anti-slop/SKILL.md` and `skills/anti-slop-python/SKILL.md`.