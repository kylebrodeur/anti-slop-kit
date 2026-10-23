# anti-slop-tools

The neutral, evidence-first lint policy kit for both languages. This repo is
VENDORED policy source: it installs into other repos; it is not an npm or
PyPI package and has no CLI. Start with
[docs/quickstart.md](docs/quickstart.md), the numbered path from nothing to a
passing policy in a consumer repo.

| Piece | What it is |
|---|---|
| [anti-slop/](anti-slop/README.md) | The Oxlint plugin source (TypeScript rules: fabricated casts, `unknown` params/returns, `Record<string, unknown>` maps, runtime `typeof` narrowing, module mocking) |
| [anti-slop-python/](anti-slop-python/README.md) | The Python policy (ruff families + ast-grep evidence rules + the `# SAFETY:` filter) |
| [setup/install-anti-slop.sh](setup/install-anti-slop.sh) | TypeScript one-command vendoring (plugin, then `tools/oxlint/anti-slop/`; skill, then `.claude/skills/`) |
| [setup/install-anti-slop-python.sh](setup/install-anti-slop-python.sh) | Python one-command vendoring plus the staged fail-closed gate wiring |
| [skills/](skills/) | Guidance skills: `anti-slop`, `anti-slop-python`, and the rule-authoring skills (`authoring-oxlint-anti-slop-rules`, `authoring-shadcn-lint-rules`) |

## Where to read next

Day-to-day tasks: [docs/how-to.md](docs/how-to.md). Full command surface and
every error string with its fix: [docs/RUNBOOK.md](docs/RUNBOOK.md). Agent
rules: [AGENTS.md](AGENTS.md).

Consumers add their own owned rule groups (product or policy names) alongside
the generic `anti-slop/*` rules; nothing here carries another project's
policy. The guidance skills install to the harness skill locations via the
installers.

## What this is not

Not a framework, not a daemon, not a compiler: it is vendored policy source
plus the skills that teach it. It lints; it does not run, serve, or host
anything. Verified 2026-10-22.

## Family

This repo is a public member of the AI ECP family: independent, single-purpose
repos. Siblings and their lanes:

- [ecp-toolkit](https://github.com/kylebrodeur/ecp-toolkit) (the `ecp`
  control-plane CLI).
- [repo-guards](https://github.com/kylebrodeur/repo-guards) (the `guv`
  repo-discipline gates).
- [actions-runner](https://github.com/kylebrodeur/actions-runner) (the
  `arun` local agent-pipeline runner).
- [agent-workspace-kit](https://github.com/kylebrodeur/agent-workspace-kit)
  (the manifest-driven role launcher for multi-agent teams).
- [docs-policy-kit](https://github.com/kylebrodeur/docs-policy-kit) (the
  `docpol` documentation policy engine).
- [op-safe](https://github.com/kylebrodeur/op-safe) (the `op://` secrets
  reference resolution).

## First-run output

A consumer repo adopted onto this policy reports findings on first run. That
is the policy working, not a failure. The one hard rule: never launder types
or evidence to make lint pass. Fix the code, parse the boundary, inject the
seam. Recipes: [skills/](skills/).