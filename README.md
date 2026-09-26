# Local AI coding stack

Local pair-programmer / agent for when cloud tokens run out. Ollama runtime +
aider (terminal pair-programmer) + opencode (agentic TUI).

## Machines

| Machine | Workhorse model | Why |
|---|---|---|
| MacBook M4 16GB | `qwen2.5-coder:14b` | biggest that fits without swap-thrash |
| PC (4090 + 96GB) | `qwen2.5-coder:32b` | ~20GB, fully GPU-resident, ~30+ t/s |
| PC heavyweight | `gpt-oss:120b` | ~65GB, split GPU+RAM, ~10-15 t/s — best open quality |

## Setup — Windows PC

```powershell
.\install-windows.ps1   # installs ollama, uv, node, aider, opencode; pulls models
.\verify.ps1            # sanity: GPU, server, models, tools, generation
.\eval\eval.ps1         # benchmark battery — same 4 tasks used on the Mac
```

Then in any project:
```powershell
aider                 # uses .aider.conf.yml -> qwen2.5-coder:32b
aider --model ollama/gpt-oss:120b   # heavyweight for hard tasks
opencode              # agentic TUI, model picker inside
```

## Eval baseline (Mac, qwen2.5-coder:14b — for comparison)

| Task | Result |
|---|---|
| t1 utils + tests | pass, 2 rounds |
| t2 LRU fix | pass, 1 round |
| t3 parser | pass, 3+ rounds + manual API fix |
| t4 multi-file | pass, 1 round |

## Setup — Mac (decommissioned — coding stack moved to desktop)

Ollama/aider/opencode binaries remain installed; the 14b/7b models were
removed to reclaim disk. To rebuild: `./install-macos.sh`.

## Honest capability notes (measured on 14b; 32b/120b are strictly better)

- Good: focused edits, bug-fixes with test feedback, multi-file mechanical
  changes, writing tests.
- Weak: one-shot "build the whole feature" (tends to stub), self-debugging
  without a pointed diagnosis, keeping public APIs stable across rewrites.
- Best loop: small task → run tests → paste the failure back. Repeat.

## Notes

- gpt-oss:120b partial-offload needs ~65GB free disk + leaves ~30GB headroom
  in RAM. Skip it if storage is tight — 32b covers 90% of coding work.
- Stop server: `ollama stop` / close tray icon (Win) or `pkill -f "ollama serve"` (Mac).
