# Questions

How to ask, log and grade every question. `session_id` is the session id from `SKILL.md`. Tool names are short here; the full names are `mcp__plugin_study_study__<tool>`.

## Tools first, then one message

Text written before a tool call in the same turn can reach the learner as a one-line summary instead of the text itself. Only the turn's last message is always shown in full. So every turn goes:

1. **Every tool call first:** `record_verdict`, task updates, helpers, `pose_question`.
2. **Then one message:** the verdict on the last answer, the teaching, and the question, in that order. It ends the turn. Nothing comes after it.

Never write a verdict, teaching or a plan and then call a tool in the same turn.

## Kinds

| Kind | When | Graded | Step | Asked with |
|---|---|---|---|---|
| `ask` | Any phase: the goal, preferences, plan changes, which goal | No | No | AskUserQuestion; up to 4 questions in one call |
| `probe` | Probe | Yes | Never | Chat |
| `predict` | Before a step, to make the learner reason toward it | Yes | Required | Chat |
| `check` | After a step | Yes | Required | Chat |

An `ask` never goes through `pose_question`: call AskUserQuestion directly and the hook logs it. Write nothing before it in the turn. Its question field shows plain text only: no code, tables or bold. An `ask` that needs a code example or a list to read, such as "start, or change the plan?", goes in chat as the turn's last line instead.

Use multiple choice when the idea comes down to telling a few options apart. Use free text when the learner has to explain why, derive something, or produce an answer that options would give away.

## A graded multiple-choice question

1. **Commit the key.** Call `pose_question`. Write the properties in this order, so the explanation is written before the key. The explanation and each key item go in base64, so a learner who opens the transcript (ctrl+o) doesn't read the answer by accident. Here the explanation is "Subtract 4 from both sides: 3x = 15. Divide both sides by 3: x = 5. 15 forgets to divide; 23/3 adds the 4 instead of taking it off." and the key is "5":

   ```json
   {
     "session_id": "<session id>",
     "kind": "check",
     "step_id": "s2",
     "question": "Solve 3x + 4 = 19. What is x?",
     "options": ["5", "15", "23/3"],
     "explanation_b64": "U3VidHJhY3QgNCBmcm9tIGJvdGggc2lkZXM6IDN4ID0gMTUuIERpdmlkZSBib3RoIHNpZGVzIGJ5IDM6IHggPSA1LiAxNSBmb3JnZXRzIHRvIGRpdmlkZTsgMjMvMyBhZGRzIHRoZSA0IGluc3RlYWQgb2YgdGFraW5nIGl0IG9mZi4=",
     "key_b64": ["NQ=="],
     "multi": false
   }
   ```

   - **Base64:** standard alphabet, UTF-8, with `=` padding. Work the explanation and key out in your thinking first, then write only their base64 in the call. Never write them in plain text anywhere the learner can see before they answer.

   - `kind` is `probe`, `predict` or `check`. `step_id` is required for `predict` and `check` and left out for `probe`.
   - `options`: 2 to 4 distinct, non-empty labels. Each wrong option is a real wrong idea a learner might hold, ideally one the probe found. Keep options alike in length and form. No "all of the above".
   - `key_b64`: a list holding the base64 of labels copied exactly from `options`. `multi: true` only when the key has more than one label. With `multi: true`, no label may hold ", ": that is how the picks of a multi-select answer are joined.
   - Options never look like a choice letter (`A`, `b.`, `(c)`): the learner answers with letters. The server refuses them.
   - The server adds "I don't know" when there are 3 or fewer options, shuffles them, and returns `{"question_id": "q3", "options": [...], "choices": ["A. 15", "B. I don't know", "C. 5", "D. 23/3"]}`.
   - `"closed": "q2"` in the result means an earlier question had no answer and was logged as skipped. Expect that only when you meant to drop it.
   - An error lists what to fix. Fix it and call again. An encoding error names the field, like `key_b64[0] does not decode to one of the options`: check the label and encode it again.

2. **Ask it in chat.** After `pose_question` returns, write the turn's one message: the teaching that leads to the question, the question, then the `choices` as a bullet list. End the turn there.

   ```markdown
   3x + 4 = 19 says two amounts match. Take the same 4 from both: 3x = 15. Then split both into 3 equal parts.

   Solve 3x + 4 = 19. What is x?

   - A. 15
   - B. I don't know
   - C. 5
   - D. 23/3
   ```

   - The question: exactly the text you sent to `pose_question`.
   - The choices: the `choices` lines, in the returned order, exactly as written, "I don't know" included. The letters map to the options in that order, so never reorder, drop or reword one.
   - Nothing after the choices, no hint and no "take your time", except one line on the first graded question of a sitting: "Answer with a letter."
   - One graded question per message.

3. **Read the hook message.** The learner's reply arrives with a hook message:

   - `q3: wrong (picked "23/3"; key "5")`: they answered with a letter or an option's exact words, and code graded it. The verdict word is `right`, `partly`, `wrong` or `dontKnow` (they picked "I don't know"). Several labels look like `picked "A", "B"; key "A", "C"`. Code logged the verdict, so don't call `record_verdict` for it.
   - `q3: answer in the learner's words, grade it with record_verdict`: they wrote more than a letter, such as a letter with their reasoning, or their own answer. Grade it from what they wrote (below) and call `record_verdict`. Their reasoning is the best evidence you get, so read all of it. A message that isn't an answer (a question back, "stop") is handled as in the free-text section, step 4.
   - `q3: free-text answer via Other, grade it with record_verdict`: the question was asked with AskUserQuestion (a lesson begun on an older version) and they typed their own answer. Grade it and call `record_verdict`.

4. **Ask for the thinking when it matters.** The learner's thinking is the main evidence, more than right or wrong, but a picked option doesn't show it. After the verdict, ask in chat how they got there when it matters: a wrong answer whose cause you can't tell, or a right answer you doubt. Ask in one short line, and not after every answer.

## A graded free-text question

1. **Commit the key.** Call `pose_question` with `free_text: true`, no `options`, and `key_b64` as a one-item list holding the model answer, both it and the explanation in base64 as above:

   ```json
   {
     "session_id": "<session id>",
     "kind": "check",
     "step_id": "s1",
     "question": "Why does subtracting 4 from both sides keep 3x + 4 = 19 true?",
     "explanation_b64": "Qm90aCBzaWRlcyBuYW1lIHRoZSBzYW1lIG51bWJlci4gVGFraW5nIDQgZnJvbSB0aGUgc2FtZSBudW1iZXIgb24gZWFjaCBzaWRlIGxlYXZlcyB0aGUgc2FtZSBudW1iZXIgb24gZWFjaCBzaWRlLg==",
     "key_b64": ["Qm90aCBzaWRlcyBhcmUgZXF1YWwsIGFuZCB0YWtpbmcgdGhlIHNhbWUgYW1vdW50IGZyb20gZXF1YWwgYW1vdW50cyBsZWF2ZXMgZXF1YWwgYW1vdW50cy4="],
     "free_text": true
   }
   ```

2. **Ask it in chat.** After `pose_question` returns, write the turn's one message, ending with the question. Then end the turn.
3. **Read the hook message.** The learner's next message comes with `q9: free-text answer linked, grade it with record_verdict`. Grade it and call `record_verdict`.
4. **A message that isn't an answer** gets linked too, such as a question back, or "stop". Reply to it. If the question still stands, pose it again with `pose_question`, which gives it a new id, and leave the old id ungraded; the reply and the question then share the message that follows that call. Never invent a verdict for a non-answer.

## When no hook message arrives

The hook can miss an answer. When an answer comes in with no hook line about it:

- Multiple choice: call `record_answer({session_id, question_id, text})` with the learner's reply as `text`, then grade it against the key you committed and call `record_verdict`. A letter means the option at that place in the `choices` you showed.
- Free text: call `record_answer` with the learner's answer as `text`, then grade it and call `record_verdict`.
- When the hook line is there, never call `record_answer`.

## Grading text

`record_verdict({session_id, question_id, verdict, note})`:

- `right`: the answer holds the key's idea, in any words.
- `partly`: some of the key's idea is there and some is missing, or the right answer with a wrong reason.
- `wrong`: the answer contradicts the key, or holds a different idea.
- `dontKnow`: they say they don't know, or make no attempt.
- `note`: one line on what was there and what was missing.

Grade against the key and the explanation you committed, not against a new idea of the answer. If they are gone from your context, `read_session` shows an unanswered question's `key_b64` and `explanation_b64`: decode them in your thinking, and never write them out before the verdict.

## Giving the verdict

Open with the verdict, plainly: "Right.", "Partly.", "Wrong." For "I don't know", skip the verdict word and go to the missing piece. Then read the answer, with its reasoning when there is any, and act:

| Answer | What it means | Do |
|---|---|---|
| Right, and the reasoning holds or there is none to read | Held | Move on |
| Right, but the reasoning shows a guess or a shaky reason | Fragile | Give the reason in a line. Check it again later, in a new form |
| Right for a wrong reason | A misconception | Treat it as a wrong answer that rests on a wrong idea, below |
| Wrong, and the answer or the reasoning shows a wrong idea (a wrong option that names one, or the same wrong answer again) | A misconception | Stop. Find the wrong idea, show where it breaks, repair it, check again in a new form before building on it |
| Wrong with no sign of an idea behind it, or "I don't know" | A gap | Teach the missing move, then check again |
| Partly | Part held | Say which part holds and which is missing. Teach the missing part |

In the probe, give the verdict in one line and don't teach yet (`probe.md`). After a `predict`, the verdict still comes first; a wrong prediction is where the step starts, not a failure.

The verdict opens the turn's message, before the next teaching and question (see "Tools first, then one message").

Never pose the next question until this one is graded.
