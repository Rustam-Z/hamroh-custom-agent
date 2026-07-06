# hamroh-custom-agent

A ready-to-fork **template** for running your own persona on top of the
[hamroh](https://github.com/Rustam-Z/hamroh) framework. hamroh is pinned as a
git submodule under `framework/`; this repo owns only *your* agent's identity —
persona, skills, memories, MCP config, reminders, and access. No framework code
is forked, so bumping the submodule keeps the engine up to date.

> **Using this template:** click "Use this template" on GitHub (or clone it),
> then make it yours — set the persona in `prompts/project.md`, drop your
> secrets into `.env`, and enable the MCPs you want in `plugins.json`.

## Setup

```bash
git clone --recurse-submodules https://github.com/<you>/hamroh-custom-agent && cd hamroh-custom-agent
# already cloned without --recurse-submodules?
git submodule update --init

claude setup-token      # opens a browser; prints a sk-ant-oat01-… token for .env

cp .env.example .env    # set TELEGRAM_BOT_TOKEN, HAMROH_OWNER_ID,
                        # CLAUDE_CODE_OAUTH_TOKEN, HAMROH_MODEL

make up                 # build framework image + your agent image, start the bot
make logs
```

`make up` runs two steps — build the framework base (`hamroh-base`), then build
your agent on top of it and start it. `docker compose up` alone won't work: the
`Dockerfile` needs `hamroh-base` to exist first.

Claude Code auth comes from `CLAUDE_CODE_OAUTH_TOKEN` in `.env` — generate it
once with `claude setup-token` (works with a Claude subscription or API) and
paste the `sk-ant-oat01-…` token in. This is the login path on every OS; no
`claude login` / Keychain / mounted credentials needed.

## Updating the framework

The framework lives as a git submodule under `framework/`, pinned to one exact
commit (detached HEAD — it doesn't track a branch). Two situations:

**You want the latest upstream framework.** Bump the pinned commit and commit the
new pointer:

```bash
git submodule update --remote framework   # fetch + check out latest upstream
git add framework && git commit -m "bump framework"
make up
```

`--remote` follows the submodule's tracked branch (the remote's default, `main`),
so you never hardcode a branch or merge into the detached HEAD by hand. On a
deployed server, `make update` does this for you (see "Updating a deployed
bot" below).

**You pulled this repo and the pointer moved** (someone else bumped it). A plain
`git pull` updates the superproject but leaves `framework/` on the old commit.
Sync it:

```bash
git submodule update --init --recursive   # --init is harmless if already initialized
make up
```

To do this automatically on every pull, set it once per machine:

```bash
git config --global submodule.recurse true
```

Either way, no files to re-copy — `system.md`, `subagents.md`, and the built-in
skills are rebuilt from the submodule at build time (`make up`).

## Updating a deployed bot

On the server, update with one command:

```bash
make update   # commit the bot's new memories, pull, bump framework to latest, rebuild
```

The bot writes its memories into `memories/` but never commits them, and an
uncommitted memory file that also changed upstream makes `git pull` abort.
`make update` runs `scripts/commit-memories.sh` first, which commits and pushes
those notes so the pull always goes through. Run the script by hand (or via
cron) anytime you want the server's memories pushed sooner.

`make update` also moves `framework/` to the latest upstream `main` and, if the
pointer moved, commits and pushes the bump — so every update runs the newest
framework without a separate bump step. Prefer a pinned, hand-picked framework
commit? Drop `--remote framework` and the `git diff --quiet framework || …`
line from the `update` target and bump manually as described above.

If you and the bot ever edit the same memory file, git keeps both sides' lines
(`merge=union` in `.gitattributes`) — no conflict markers to resolve by hand.
Skim the merged file if you both touched the same lines.

## How it works

Two layers:

- **`framework/`** — the hamroh engine, pinned as a git submodule to one exact
  commit. It ships the Dockerfile, the base system prompt, the built-in skills,
  and all the Python. You never edit it.
- **This repo** — your agent's identity. The build stacks it onto the framework:

```
agent image = hamroh-base (built from framework/) + your agent baked on top
├── /app/hamroh                engine + framework skills                (framework)
├── /app/prompts/ (system.md,  ← COPY framework/prompts/                (from submodule)
│      subagents.md, …)
├── /app/prompts/project.md    ← COPY prompts/project.md                (this repo)
└── /app/skills/<yours>        ← COPY skills/  (merges onto built-ins)  (this repo)

mounted live at runtime (nothing baked there to hide):
├── /app/plugins.json            ◄── ./plugins.json
├── /app/access.json             ◄── ./access.json
├── /app/default-reminders.json  ◄── ./default-reminders.json
├── /app/memories/               ◄── ./memories/
└── /app/data/                   ◄── ./data/
```

**Why `prompts/` and `skills/` are baked, not mounted.** A directory bind-mount
*masks* whatever the image baked at that path — it replaces, it doesn't merge.
The image fills `/app/prompts` (`system.md`) and `/app/skills` (the built-ins),
so mounting your own folder there would hide them. A Dockerfile `COPY` merges
instead: the framework's files survive and yours are added on top. Single files
(`plugins.json`, `access.json`, `default-reminders.json`) and dirs the image
leaves empty (`memories/`, `data/`) have nothing to mask, so those stay mounts
— and stay live-editable.

**When changes take effect:**

| Change | Applies |
|---|---|
| `access.json` | live (hot-reloaded) |
| `memories/` | live (read and written on demand) |
| `plugins.json`, `default-reminders.json` | on `docker compose restart` |
| `prompts/`, `skills/` (baked) | on rebuild — `make up` |

## What this repo owns

| File / dir | Configures | Git-tracked |
|---|---|---|
| `prompts/project.md` | Persona / system-prompt overlay (baked) | ✅ |
| `skills/` | Your custom skills (baked; framework's are inherited) | ✅ |
| `memories/` | The bot's memory — it reads and writes here | ✅ |
| `plugins.json` | Tools + MCP capability surface | ✅ |
| `default-reminders.json` | Scheduled reminders | ✅ |
| `access.json` | Access policy (DM / group) | ✅ |
| `Dockerfile` | Bakes the above onto the framework image | ✅ |
| `.env` | Bot token, owner id, model, MCP secrets | ❌ secrets |
| `data/` | SQLite, session state, logs | ❌ runtime |

`system.md`, `subagents.md`, and the built-in skills are **not** in this repo —
they come from the framework (baked at build). `access.json` is the tracked
source of truth; owner commands `/allow`, `/deny`, `/dmpolicy` edit it live, so
after using them commit the change to persist it.

## Customizing

- **Persona** → edit `prompts/project.md` (set the name — it ships as `MyBot`),
  then `make up` (baked).
- **Skills** → drop a `skills/<name>/SKILL.md` folder, then `make up` (baked).
- **MCPs** → in `plugins.json` set an MCP `"enabled": true`, add its secret to
  `.env`, then `docker compose restart`. See `framework/docs/tools.md`.
- **Reminders** → add entries to `default-reminders.json`, then restart.
- **Memories** → add `memories/**/*.md` with `name` + `description` frontmatter
  (live, no restart).

## Installing extra packages

Need a system binary (ffmpeg, a font) or an extra Python dep for a custom tool?
Add it to the `Dockerfile` — it already builds `FROM hamroh-base`:

```dockerfile
RUN apt-get update && apt-get install -y --no-install-recommends ffmpeg \
    && rm -rf /var/lib/apt/lists/*
RUN /app/.venv/bin/pip install --no-cache-dir yt-dlp
```

Then `make up`. Never edit `framework/` — it's the pinned submodule.
