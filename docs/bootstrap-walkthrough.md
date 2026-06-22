# Bootstrap Walkthrough: from an empty repo to the first decision

This document is a worked example so a first-time starter user can preview *what conversation actually happens*. It's a record of following one session, not a list of commands. If `README.md` covers "what's inside" and `PROMPTS.md` covers "what you paste," this document covers "what happens after you paste."

The example project is fictional: an **internal library-loan management app (working name `booklog`)**, one full-stack developer plus one backend coworker. Assume the stack is TypeScript + Postgres. Substitute your real project as you read.

It's written with three readers in mind.

- **The agent (AI)**: learns the same "what to read before answering" in a new repo.
- **The solo user**: lays down the skeleton and fills the blanks without memorizing commands.
- **A teammate**: plants the same structure in their own project to collaborate under the same rules.

---

## Step 0: copy and setup

From the new project root. `<source>` is the path where you got the starter.

```bash
cp -R <source>/templates/agentic-starter/. .
bash scripts/setup.sh
```

The dot at the end of `starter/.` means "all folder contents including hidden files," and the final `.` means "into the current folder." You need this so hidden folders like `.agent` and `.claude` come along.

The setup output looks roughly like this.

```text
==> 1/4 Install git hooks
  git hooks enabled (core.hooksPath = .githooks)
==> 2/4 Multi-host router verify
  [OK] host instruction files in sync
==> 3/4 Verify AI tools
  [OK] gstack / GSD / code-review-graph  (MISSING if absent, not blocking)
==> 4/4 Agent starter wiring verify
  Agent starter verify passed.
```

If a tool shows `MISSING`, it doesn't stop. The starter is a skeleton, not a tool installer.

---

## Step 1: the first run prompt

Paste the "1. greenfield init" prompt from `PROMPTS.md` into the current host as is. The core of what it tells the AI:

> Apply agentic-starter to this repo. First read the current host router and `.agent/Instructions.md`, `.agent/Context.md`, `.agent/Memory.md`. Then replace the `{{...}}` placeholders and `YYYY-MM-DD` based on this project. Closed decisions are named `D-YYYYMMDD-<author>-<slug>`; open questions go to `.planning/threads/`. Report the verification command results at the end.

The agent reads first. At this step, a good agent *doesn't replace right away* and instead asks about the blanks it doesn't know.

> **Agent**: I read the 4 routers and the three `.agent/` files. To replace, I need the following.
> 1. A one-line product description and scope (what it does and doesn't do)
> 2. Team composition and roles
> 3. The stack and where "silent failures" tend to happen (e.g., forgetting to apply a migration)
> 4. Any preferences or rules already decided

Here the person answers.

> **Person**: It's an internal library-loan management app. Loans, returns, overdue notifications. Recommendations and public exposure are out of scope. Me (full-stack) and one backend coworker. TypeScript + Postgres. When I add a migration, I have to confirm it applies locally. Keep answers short and in Korean.

---

## Step 2: placeholder replacement

The agent fills the blanks in `.agent/Context.md` and `CLAUDE.md`. For example, the "code safety" section of `CLAUDE.md` becomes this.

```markdown
## Code safety (load-bearing)

- After adding or changing a migration, confirm it applies locally (`<apply command>`).
- Never print or commit secrets and credentials.
- Handle loan state transitions in a transaction (prevents double loans).
```

`{{product-name}}` becomes `booklog`, `{{stack}}` becomes `TypeScript + Postgres`, and `YYYY-MM-DD` becomes today's date. `@git_author` stays untouched: at commit time, a git hook replaces it with `git config user.name`.

The `{{rules-1-to-4}}` in `.claude/hooks/memory-selfcheck.sh` also get filled. These four lines are a reminder that prompts the agent every turn with "did you check this before responding," so leaving the sample text in place makes them meaningless. Change them to the rules this project breaks most often.

```text
- Confirm local apply first when adding a migration
- No printing secrets
- Read the 3 .agent files before answering
- Loan state transitions run in a transaction
```

---

## Step 3: the first decision, open questions to a thread

Once replacement is done, the real work starts. One closed decision emerges.

> **Person**: DB is confirmed as Postgres. Because the coworker is familiar with it and we need transactions.

The agent copies `D-template.md` to `docs/wiki/decisions/D-20260623-dana-postgres-over-sqlite.md` (today's date, git handle, slug), then runs `bash scripts/decisions-index.sh` to regenerate the index. The body records the options (e.g., SQLite vs Postgres), why they were rejected, and the reversal conditions.

Questions that aren't closed yet, by contrast, don't become ADRs.

> **Person**: I'm not sure yet whether to do overdue notifications by email or push.

This goes to `.planning/threads/`, not a decision file. ADRs hold only "closed decisions." Promote it when a conclusion lands.

> There is no next number to compute. A decision id is today's date, your git handle, and a slug (`D-YYYYMMDD-<author>-<slug>`), so two people on parallel branches never collide. After writing the file, run `bash scripts/decisions-index.sh` to refresh the index.

---

## Step 4: what the git hook does

When you commit the decision file, the pre-commit hook does two things automatically.

```text
[bumped] frontmatter `updated_at:` -> 2026-06-22:
  - docs/wiki/decisions/D-20260623-dana-postgres-over-sqlite.md
[substituted] frontmatter `@git_author` -> <git user.name>:
  - docs/wiki/decisions/D-20260623-dana-postgres-over-sqlite.md
```

It updates `updated_at` to today and replaces `@git_author` with the actual commit author. The prepare-commit-msg hook appends one line to the `audit_log`. The person doesn't have to fix the date by hand every time.

If `gitleaks` is installed, it also scans for secrets. If not, it skips quietly (it doesn't block the commit).

---

## Step 5: verification

```bash
bash scripts/setup.sh
bash scripts/verify-agent-ssot.sh
bash scripts/wiki-lint.sh
git diff --check
```

- `verify-agent-ssot.sh` checks the skeleton wiring (4 routers in sync, `.agent` links, hook syntax).
- `wiki-lint.sh` checks `docs/wiki/` integrity (orphans, broken links, duplicate ids, dangling relations). It also catches whether the decision file you just made is registered in the index.
- `git diff --check` catches leftover errors like trailing whitespace.

The last recommended step is a *smoke check*. Copy the starter once into an empty directory and run setup/verify end to end. Walking the exact path a first-time user takes is what surfaces the "works only on my machine" traps.

---

## What one session left behind

| File | What went in |
|---|---|
| `CLAUDE.md` + 3 routers | product name, stack, code safety rules replaced |
| `.agent/Context.md` | product scope, team, stack summary |
| `.agent/Memory.md` | a preference line or two, like "keep answers short in Korean" |
| `.claude/hooks/memory-selfcheck.sh` | this project's 4 load-bearing rules |
| `docs/wiki/decisions/D-20260623-dana-postgres-over-sqlite.md` | the first closed decision (DB = Postgres) |
| `.planning/threads/` | the open question (notification method) |

The next session's agent reads these files and knows, without the person explaining again, that "the DB is set to Postgres, and the notification method is still open." That's the point of this skeleton.

---

## What the starter guarantees / doesn't

| Guarantees | Doesn't guarantee |
|---|---|
| an empty operating skeleton (layers, router, hooks, wiki, planning) | product knowledge (that's what a new project fills in) |
| router-sync and `.agent`-link wiring verification | identical behavior on every host (Cursor needs a direct check in a new chat) |
| re-runnable setup | installing the tools themselves (gstack/GSD/code-review-graph) |

The starter is a starting point, not a framework. After copying, you have to pass replacement, installation, and verification yourself.
