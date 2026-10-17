# Token savers

Three tools that cut how many tokens Claude Code spends. They work at different
layers, so they stack:

| Tool | Layer | What it does |
|---|---|---|
| rtk (Rust Token Killer) | Bash tool output | A `PreToolUse` hook rewrites shell commands (`git status` becomes `rtk git status`) so their output comes back filtered. |
| caveman | Model replies | A Claude Code plugin that makes Claude answer in compressed "caveman" style. It also adds cavecrew agents and caveman skills. |
| headroom | API traffic | A local proxy on `127.0.0.1:8787` that compresses tool output, logs and file reads before they reach the model. |

## rtk

1. Install the CLI (version used here: `rtk 0.49.0`):
   ```bash
   brew install rtk          # macOS
   # or: cargo install rtk
   ```
   Check it with `rtk gain`. If that fails, you have the other `rtk` (Rust Type Kit) installed.
2. Copy `RTK.md` to `~/.claude/RTK.md` and add this line to `~/.claude/CLAUDE.md`:
   ```
   @RTK.md
   ```
3. Add the hook to `~/.claude/settings.json`:
   ```json
   "hooks": {
     "PreToolUse": [
       { "matcher": "Bash", "hooks": [ { "type": "command", "command": "rtk hook claude" } ] }
     ]
   }
   ```

## caveman

The plugin source is <https://github.com/JuliusBrussee/caveman>. It is not
copied here. Install it inside Claude Code:

```
/plugin marketplace add JuliusBrussee/caveman
/plugin install caveman@caveman
```

That gives the same result as these entries in `~/.claude/settings.json`:

```json
"enabledPlugins": { "caveman@caveman": true },
"extraKnownMarketplaces": {
  "caveman": { "source": { "source": "github", "repo": "JuliusBrussee/caveman" } }
}
```

Switch the level with `/caveman lite|full|ultra|off`. Say "normal mode" to turn it off for a session.

## headroom

`install-headroom.sh` installs [headroom-ai](https://github.com/headroomlabs-ai/headroom)
with `uv`. It then registers the proxy as a persistent service on port 8787 and runs a health check.

```bash
./install-headroom.sh          # install + start the service
./install-headroom.sh --check  # only verify an existing install
```

The script is macOS only. It uses `brew` and a launchd service. On Windows, run
`uv tool install --python 3.13 "headroom-ai[all]"` and then see `headroom install --help`.

Installing the proxy does not route Claude Code through it. To route Claude Code,
add this to `~/.claude/settings.json`:

```json
"env": { "ANTHROPIC_BASE_URL": "http://127.0.0.1:8787" }
```

With that set, Claude Code cannot reach the model while the proxy is down.
Check and revive the proxy:

```bash
headroom install status
headroom install start
headroom savings     # how much was saved
```

To undo: remove the `env` entry and run `headroom install remove`.
