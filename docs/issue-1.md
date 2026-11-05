# Issue 1 - summarized teaching and readable answer keys

kadeski/study#1. Decided with the maintainer on 2026-11-05. Shipped in 1.0.3; 1.0.4 re-ships it without the dev files 1.0.3 carried by mistake.

## What was found

Reproduced on Claude Code 2.1.318 with study 1.0.1, one teach -> `pose_question` -> AskUserQuestion turn per output style:

- **Concise style:** the teaching came back from the API as a thinking block whose signature is tagged `narration`, holding a one-line summary. The full text is in neither the screen nor the transcript file. Short status lines before tool calls stayed text.
- **Default style:** the same turn came back as plain text and rendered in full.
- In both runs Claude Code sent `thinking.display: "updates"`, which lets the server summarize prose that comes before a tool call. The output style feeds the server's choice. One sample per style.
- **The AskUserQuestion dialog renders no markdown.** Code blocks, inline code and tables show as raw text in its `question` field.
- **ctrl+o shows every tool input in plain text**, `pose_question`'s `key` and `explanation` included.

## Decisions

### 1. Prose ends the turn (Problem 1)

Every tool call of a turn comes first. The turn's prose is one message, at the end, and nothing follows it. That is the only text the server never summarizes.

- **Graded multiple choice is asked in chat.** `pose_question` returns `choices`, the options as lettered lines (`A. KeyError`) in the shuffled order. The message ends with the question and those lines, copied exactly. The learner types a letter or a label.
- **The prompt hook grades it by code**, as the dialog path does now. It code-grades only a message that is exactly:
  - one letter A to D, any case, optionally followed by `.` or `)`, or wrapped as `(a)`;
  - one option label, ignoring case and outer spaces;
  - for a `multi` question, a comma-separated list of those.

  Anything else is logged as `other` and comes back as `q3: answer in the learner's words, grade it with record_verdict`. The teacher grades it, or treats it as a non-answer. A misparse can't be undone, because `record_verdict` refuses a question code already graded. So the grammar stays narrow.
- **`pose_question` refuses an option that reads like a choice letter** (`A`, `b.`, `(C)`), so a letter answer never collides with a label.
- **AskUserQuestion is only for ungraded asks.** Nothing comes before it in the turn. Its `question` field holds plain text only.
- A graded question asked through the dialog still grades (the `answer` hook is unchanged), so a lesson begun on 1.0.2 finishes.
- **Problem 3** (the dialog covers the teaching) goes away: the question sits in chat, right under the teaching.

### 2. Spoilers go in base64 (Problem 2)

- `pose_question` takes `explanation_b64` and `key_b64` in place of `explanation` and `key`. `commit_problem` takes `solution_b64` in place of `solution`. New names, so a call that follows stale instructions fails on the schema, instead of plaintext being decoded as base64.
- The server decodes strictly: standard base64 alphabet, padding required, UTF-8, not blank after trimming. A multiple-choice key must decode to one of the options.
- **Errors never quote decoded text.** They name the field and position only, like `key_b64[0] does not decode to one of the options`, because a tool result shows in ctrl+o too.
- The log keeps plaintext, as before. The hook, grading and `record` are unchanged.
- `read_session` and `start_session`'s `lastSitting` return a question with no answer and no verdict with `key_b64` and `explanation_b64` in place of the plaintext fields. A teacher that lost its context can still grade it.
- This blocks a glance, not a reader who decodes base64. Also out of reach: the data folder's files, and thinking summaries when a learner turns on `showThinkingSummaries`.

### 3. The whole class (Problem 1's pattern everywhere)

Every skill instruction that puts prose before a tool call in one turn follows the rule in decision 1:

- `questions.md`: asking a graded multiple-choice question; giving a verdict and then posing the next question.
- `teach.md`: one move per message; moving past a step (task updates and the extractor before the prose); opening a picture or demo.
- `probe.md`: the one-line verdict before the next probe question; grouped `ask` questions.
- `plan.md`: the plan list, then the "start or change" question, which is now asked in chat.
- `study/SKILL.md`: the rule itself, under "Rules that never drop"; step 6's "feels obvious" question after a verdict; `/study stop`.
- `practice/SKILL.md` and `method.md`: commit, then show; conclude, then reveal.
- `import-notes/SKILL.md`: start the extractors, then report.

## Docs

`contracts.md` gets the new tool fields, the `choices` result and the hook grammar. `spec.md` follows. `checks.md` records the findings above.

## Done means

- The step 1 repro, rerun in Concise style on 1.0.3: the teaching renders in full, and the transcript holds it as text, not `narration`.
- ctrl+o shows `key_b64` and `explanation_b64`, not the key.
- A typed letter is graded by code, and the hook line names the verdict.
- `plugin.json` is 1.0.3, `main` is pushed, and `dev/release.sh` has pushed `release`.
