# Example: vendor the policy into a consumer repo

**What this shows:** the whole path from an empty consumer repo to a real
finding the policy catches, and the two ways to resolve it.

Every command here is real. The outputs were captured by running this
sequence end to end.

## 1. Make a consumer repo

```bash
mkdir -p /tmp/consumer && cd /tmp/consumer
git init -q
```

The lint config is a TypeScript file that uses ESM syntax, so the consumer
needs a `package.json` that says so. Without `"type": "module"`, node
reparses the config as ESM on every run and prints a warning:

```bash
cat > package.json <<'JSON'
{
  "name": "consumer",
  "version": "1.0.0",
  "type": "module",
  "private": true
}
JSON
```

## 2. Vendor the TypeScript policy

```bash
bash /path/to/anti-slop-tools/setup/install-anti-slop.sh
```

Expected output:

```
📦  Vendoring anti-slop plugin -> tools/oxlint/anti-slop
📋  No Oxlint config found: write one wiring tools/oxlint/anti-slop (see .../anti-slop/README.md).
🧠  Installing anti-slop guidance skill -> /tmp/consumer/.claude/skills/anti-slop/SKILL.md

✅  Plugin vendored. Remaining manual steps:
    1. Install dev deps (keep versions in lockstep):
         npm add -D oxlint@1.85.0 @oxlint/plugins@1.80.0
    2. Add a script:  "lint:anti-slop": "oxlint -c oxlint.config.ts src"
    3. Add this repo's own rule group separately if it has local policy.
    4. Run it. Findings in owned source are expected on first run.

    Do NOT suppress rules or add casts just to make lint pass.
```

Two things to notice: the plugin lands in `tools/oxlint/anti-slop/` (the
consumer's own tree, not a dependency), and the skill lands in the
harness's skill location.

The installer does NOT write the lint config, so the next step is
manual.

## 3. Write the lint config

The plugin needs an `oxlint.config.ts` that points at the vendored copy
and enables the rules. Create it at the consumer root:

```ts
// oxlint.config.ts
import { defineConfig } from "oxlint";
export default defineConfig({
  jsPlugins: [{ name: "anti-slop", specifier: "./tools/oxlint/anti-slop/index.ts" }],
  rules: {
    "anti-slop/no-unknown-parameters": "error",
    "anti-slop/no-unsafe-dictionary-type": "error",
    "anti-slop/require-safety-comment-for-type-assertion": "error",
  },
});
```

The full rule list is in
[../anti-slop/README.md](../anti-slop/README.md). This example enables
three of them.

## 4. Write source the policy objects to

```ts
// src/thing.ts
export function pick(data: Record<string, unknown>, key: string) {
  return data[key] as string;
}
```

`data[key]` is `unknown`, and the `as string` is a fabricated cast.

## 5. Install the dev deps and run the policy

```bash
npm install -D oxlint@1.85.0 @oxlint/plugins@1.80.0
npx oxlint -c oxlint.config.ts src
```

Expected output (two findings, one per rule):

```
src/thing.ts:1:28: error anti-slop(no-unsafe-dictionary-type): This dictionary's unknown value type gives callers no concrete value contract. Use an owner/schema-derived value type; parse external payloads before insertion.
src/thing.ts:2:10: error anti-slop(require-safety-comment-for-type-assertion): This type assertion has no `SAFETY:` justification. State the checked invariant immediately before the assertion or its containing statement.

Found 0 warnings and 2 errors.
Finished in 99ms on 1 file with 99 rules using 8 threads.
```

The finding is the point. The policy is evidence-first: it names the
rule, it does not guess.

## 6. Fix the source, not the policy

**Path A: type the dictionary properly.**

```ts
export function pick(data: Record<string, string>, key: string) {
  return data[key];
}
```

Re-run the lint:

```
Found 0 warnings and 0 errors.
Finished in 99ms on 1 file with 99 rules using 8 threads.
```

**Path B: keep the shape, justify the assertion.**

```ts
export function pick(data: Record<string, unknown>, key: string) {
  // SAFETY: the caller validated the payload shape before this call.
  return data[key] as string;
}
```

Re-run the lint. The assertion finding is gone; the dictionary finding
remains, because the dictionary is still untyped:

```
x anti-slop(no-unsafe-dictionary-type): This dictionary's unknown value type gives callers no concrete value contract. Use an owner/schema-derived value type; parse external payloads before insertion.
   ,-[src/thing2.ts:1:29]
 1 | export function pick2(data: Record<string, unknown>, key: string) {
   :                             ^^^^^^^^^^^^^^^^^^^^^^^
 2 |   // SAFETY: the caller validated the payload shape before this call.
   `----

Found 0 warnings and 1 error.
```

Both paths are legitimate. The `SAFETY:` comment records the invariant
you checked, so the next reader can verify it.

**Never suppress a rule to make the lint pass.** If a rule is wrong for
your repo, fix the rule in its own repo, where the change is reviewable.

## The Python lane

The Python policy vendors the same way:

```bash
bash /path/to/anti-slop-tools/setup/install-anti-slop-python.sh
```

It brings the ruff families, the ast-grep evidence rules, and the
`# SAFETY:` filter. The ast-grep rules require a justification comment
next to a cast or a bare ignore, so the evidence for a suppression is
part of the code.

See [../anti-slop-python/README.md](../anti-slop-python/README.md) for the
rule list and the filter's behavior.
