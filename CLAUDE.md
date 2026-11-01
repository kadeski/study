# CLAUDE.md

This repository is the `study` plugin for Claude Code. The repository root is the plugin folder, so everything tracked here ships to the people who install it.

## Commands

- `dev/check.sh` - run before every commit. Needs `jq` and the `claude` CLI. It checks the manifest, README, LICENSE, icon and skills, the file rules the plugin directory enforces, credential-like names in `${...}`, that the Python parses as 3.9, runs the unit tests and `claude plugin validate --strict`. It warns when the plugin changed since origin/main but its version did not.
- `dev/hooks/pre-commit` runs `dev/check.sh` and blocks a failing commit. Turn it on once per clone with `git config core.hooksPath dev/hooks`.
- Tests: `python3 -m unittest discover -s tests`. Run them with `/usr/bin/python3` (3.9) too.

## Where things are

- `docs/spec.md` is the design, `docs/contracts.md` pins the interfaces between the parts, and `docs/checks.md` records what was checked on the platform and the decisions that followed.

## Rules

- Python 3.9 or newer, standard library only. Entry scripts run as `python3 -I`.
- Raise `version` in `.claude-plugin/plugin.json` with every release. The kadeski marketplace in kadeski/skills lists study from this repository, and the Anthropic plugin directory tracks `main`: it scans each new commit there as a version.
- Keep the plugin at the repository root. From a subfolder, the directory holds every version for a reviewer because it can't follow the hook's Python script.
- The directory's scan reads text loosely. It took an error message that told the caller to "pass" a goal id for reading a credential, and a mention of web addresses in an agent prompt for sending data, and held the plugin for the pair. Write "give" rather than "pass" before a name, and keep web addresses out of prompts unless they are needed.
- Writing style: simple terms, plain dashes (never em dashes), no filler.
