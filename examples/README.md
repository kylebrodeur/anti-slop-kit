# Examples

Worked examples of consuming this kit. Each one is runnable, and the
outputs are captured from real runs.

| Example | What it shows |
|---|---|
| [vendor-into-a-consumer.md](vendor-into-a-consumer.md) | The path from an empty consumer repo to a real finding the policy catches, and the two ways to resolve it. |
| [vendor-into-a-consumer.sh](vendor-into-a-consumer.sh) | The same sequence, scripted end to end in a throwaway temp dir. |

## Run it

```bash
bash examples/vendor-into-a-consumer.sh
```

It creates a consumer repo in a temp dir, vendors the policy into it,
writes the lint config and a source file the policy objects to, runs the
lint, then fixes the source and runs the lint again. It prints what it
does and never writes outside the temp dir.

The full install path is in
[../docs/quickstart.md](../docs/quickstart.md). This directory is the
shortest route to seeing the policy work.
