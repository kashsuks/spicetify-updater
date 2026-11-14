# spicetify-updater

Re-applies Spicetify after Spotify updates itself. macOS only.

> Work in progress: `run` is a stub until milestone 1 is done.

## Usage

```
spicetify-updater [command] [options]
```

| Command | What it does |
|---|---|
| `run` (default) | Re-patch Spotify if needed |
| `status` | Show the current state without changing anything |

| Option | What it does |
|---|---|
| `-q` / `-v` | Quiet / verbose output |
| `--dry-run` | Show what would happen without doing it |
| `--no-relaunch` | Don't reopen Spotify after patching |
| `-h`, `--help` | Show help |

## Status

`spicetify-updater status` shows what it detects without changing anything:

```
Spicetify    2.46.4 (/opt/homebrew/bin/spicetify)
Spotify      1.3.9.2055
Backup       1.3.9.2055.g806b5b278de8 (made with Spicetify 2.46.4)
Patch        present
Theme        marketplace
Extensions   spicetify-jam.js
Custom apps  marketplace

✓ up to date
```

It exits `0` when everything is up to date and `10` when a re-patch is needed, so scripts can use `spicetify-updater status -q` and check the exit code.

## Logs

Every run is logged to `~/Library/Logs/spicetify-updater/YYYY-MM-DD.log`, including debug messages and the output of every command it runs. Set `NO_COLOR=1` to turn off colors in the terminal.

## Exit codes

| Code | Meaning |
|---|---|
| 0 | Success, or nothing to do |
| 1 | Preflight failed (e.g. not macOS) |
| 2 | Spicetify CLI update failed |
| 3 | Backup or apply failed |
| 4 | Verification failed |
| 5 | Another run is already in progress |
| 10 | `status`: a re-patch is needed |
| 64 | Invalid command or option |
