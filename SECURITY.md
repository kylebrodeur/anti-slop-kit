# Security policy

## Supported

This is a static policy kit: shell installers, lint rule sources, YAML, and
markdown. There is no runtime service, no network listener, and no
installable package, so there are no supported release branches; fixes land
on the default branch.

## Reporting

Report a vulnerability privately: open a GitHub security advisory on this
repository ("Report a vulnerability" under the Security tab). Do not open a
public issue for an unpatched vulnerability.

## Scope

In scope:

- `setup/install-anti-slop.sh` and `setup/install-anti-slop-python.sh`:
  anything that executes on a contributor's or consumer's machine, including
  path handling, `--force` behavior, and what gets copied and where.
- Rule sources under `anti-slop/` and the ast-grep YAML under
  `anti-slop-python/`: a rule that fails open (silently does not fire) is a
  correctness defect with security relevance for the policy's consumers.
- The SAFETY filter (`ast-grep/filter_safety.py`): a bypass that hides
  findings is a policy bypass.

Out of scope: the Oxlint engine itself, ruff, ast-grep, and the harness are
upstream tools; report those to their own projects.

## What to include

The affected file and path, the input or sequence that triggers the defect,
and the expected vs actual behavior. A failing case as a fixture (like
`anti-slop-python/tests/fixtures/evidence_rules.py`) is ideal.

## Response

Acknowledgement within 7 days; a fix or an explicit disposition within 30.
Findings that change a rule or a gate are recorded in the repo's docs so the
policy change is auditable.