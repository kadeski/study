# study

`study` is a Claude Code plugin that teaches you one goal across as many sessions as it takes. It first finds out what you already know, then plans the shortest path from there to the goal, then teaches one reasoning step at a time with a check after each step. Later you can practice what you learned, and everything you were taught goes into a knowledge graph that later sessions read.

It works in a normal Claude Code chat: checks come in the chat as lettered multiple choice or as open questions, and you answer by typing. It runs in the terminal, the desktop app and VS Code.

## Install

In Claude Code:

```
/plugin marketplace add kadeski/skills
/plugin install study@kadeski
```

When you enable it, Claude Code asks for a data folder (default `~/Study`). Your goals, answers and knowledge graph are kept there as plain JSON files.

Study needs `python3` (3.9 or newer) on your `PATH`. It uses the standard library only.

To stop Claude Code asking before each Study tool call, allow the whole Study server once, for example in `/permissions`: `mcp__plugin_study_study`.

## Usage

- `/study <goal>` - start a goal, or continue an unfinished one. `/study stop` ends the session for now.
- `/practice [topic]` - practice what you were taught, with problems that don't say which idea they need. `/practice stop` ends it.
- `/graph` - open your knowledge graph as a page in the browser.
- `/import-notes <path>` - add your own notes (markdown, text or PDF) to the knowledge graph. Re-import an edited file to update it, or `--remove` to take its ideas back out.

Claude can also look up what you studied when it would help an answer, without changing anything.

To see the `/study` plan as a task list on models newer than Opus 4.7, Sonnet 4.6 and Haiku 4.5, which leave Claude Code's task tools out by default, start Claude Code with `CLAUDE_CODE_ENABLE_TODO_TOOLS=1 claude` (or set that variable under `env` in `~/.claude/settings.json`).

Pictures and demos are saved in the goal's folder and opened in your browser. If Python Playwright is installed, Claude checks them by rendering them first; otherwise it says it skipped the check.

## Privacy

- Everything Study saves stays in your data folder on your computer: your goals and plans, your answers and the messages you type during a Study session, and the knowledge graph. The plugin's own code sends none of it anywhere. Delete the folder to remove it.
- A small MCP server runs on your computer with `python3`. It reads and writes only the data folder.
- Hooks run on each message you send and each answer you pick in a question dialog, in every Claude Code session. Outside a Study session they exit at once and do nothing. During one, they save your answers and messages to the data folder.
- Helper agents run in the background during a lesson. The researcher checks facts with Claude's web search and web fetch tools, so its search terms leave your computer the way any web search does. The PDF reader reads PDFs you give it. The picture and demo helpers write files to the goal's folder.
- `/graph` builds a page that works offline and opens it in your browser.

## License

MIT. See [LICENSE](LICENSE). The method follows ideas from [LearnHarness](https://github.com/amosblomqvist/learnharness); no text or code is copied from it.
