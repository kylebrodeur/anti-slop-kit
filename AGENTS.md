# AGENTS.md

Rules for an agent working in `anti-slop-tools`. This is a policy kit, not an
application: the deliverables are written rules and the skills that teach them.

## What this repo is

A vendored, neutral lint policy kit. Two policy sources and two installers:

- `anti-slop/` and `anti-slop-python/` are **sources of truth** that other
  repos vendor into themselves under `tools/`. They are not packages: there is
  no installable CLI, no `pyproject.toml`, no runtime, no app.
- `setup/install-anti-slop.sh` and `setup/install-anti-slop-python.sh` are the
  vending entry points; the skills under `skills/` ride along with what they
  install.

## Rules

- `anti-slop/` is upstream owned (the canonical Oxlint plugin). Do not
  hand-edit its TS rules; refresh the whole tree from upstream and record the
  new provenance date instead.
- `anti-slop-python/` is synthesized, not upstream owned. You may port and
  adapt its ruff families and ast-grep evidence rules when a source port ships
  a better one.
- Never edit a vendored copy's config to make the lint pass. The policy is
  fail-closed: a finding is fixed at the code, never suppressed or downgraded.
- Never weaken a rule's rationale or gate in its own description (`# SAFETY:`
  comments live in target code, not in the shipped source).
- Keep every file product neutral: no product names, no owned rule-group
  prefixes, no vendor branding.
- Both installers must stay in lockstep with the Oxlint baseline they pin.
- Verify all changes that touch the policy or its installers, before and
  after. Run the two policy lanes directly (see `docs/quickstart.md` for
  commands). Verify shell scripts with `bash -n` and `shellcheck`.
- Confirm your changes are complete before you claim to be finished. If a
  gate fails, finish the work, do not stop or hand back.

## Boundary

This repo does not host a repo-specific lint config, does not run against its
own Python source (it has none: there are no pyproject or pytest files), and
does not carry product or vendor policy. It is a policy source, not a policy
consumer.

## Next doc

Start with [`docs/quickstart.md`](docs/quickstart.md) for commands; the full
error and fix surface is in [`docs/RUNBOOK.md`](docs/RUNBOOK.md).