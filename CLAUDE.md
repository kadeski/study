# CLAUDE.md

This repository is the `study` plugin for Claude Code. The repository root is the plugin folder. `main` also holds what doesn't ship (tests, docs, dev tooling, this file); the `release` branch holds only the plugin.

## Commands

- `dev/check.sh` - run before every commit. Needs `jq` and the `claude` CLI. It checks the manifest, README, LICENSE, icon and skills, the file rules the plugin directory enforces, credential-like names in `${...}`, that the Python parses as 3.9, runs the unit tests and `claude plugin validate --strict`. It warns when the plugin changed since origin/main but its version did not.
- `dev/hooks/pre-commit` runs `dev/check.sh` and blocks a failing commit. Turn it on once per clone with `git config core.hooksPath dev/hooks`.
- Tests: `python3 -m unittest discover -s tests`. Run them with `/usr/bin/python3` (3.9) too.
- `dev/release.sh` - after a release commit is on `main`, builds the `release` branch from HEAD without the top-level entries listed in `dev/not-shipped`, checks it with `claude plugin validate --profile directory` and pushes it. A new top-level file that shouldn't ship goes in `dev/not-shipped`; `dev/check.sh` validates the same cut.

## Where things are

- `docs/spec.md` is the design, `docs/contracts.md` pins the interfaces between the parts, and `docs/checks.md` records what was checked on the platform and the decisions that followed.

## Rules

- Python 3.9 or newer, standard library only. Entry scripts run as `python3 -I`.
- Raise `version` in `.claude-plugin/plugin.json` with every release. The kadeski marketplace in kadeski/skills and the Anthropic plugin directory both read the `release` branch; the directory scans each new commit there as a version.
- Keep the plugin at the repository root. From a subfolder, the directory holds every version for a reviewer because it can't follow the hook's Python script. Dev files left in the release tree drew holds and warnings too (`docs/checks.md`).
- The listing icon is `.claude-plugin/icon.png`, rendered from `dev/icon.svg` with `rsvg-convert -w 1024 -h 1024`. The directory took it at the first submission and won't take a new one.
- The directory's scan reads text loosely. It took an error message that told the caller to "pass" a goal id for reading a credential, and a mention of web addresses in an agent prompt for sending data, and held the plugin for the pair. Write "give" rather than "pass" before a name, and keep web addresses out of prompts unless they are needed.
- Writing style: simple terms, plain dashes (never em dashes), no filler.
