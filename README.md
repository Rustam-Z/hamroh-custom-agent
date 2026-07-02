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

cp .env.example .env    # set TELEGRAM_BOT_TOKEN, HAMROH_OWNER_ID, HAMROH_MODEL

make up                 # build framework image + your agent image, start the bot
make logs
```

`make up` runs two steps — build the framework base (`hamroh-base`), then build
your agent on top of it and start it. `docker compose up` alone won't work: the
`Dockerfile` needs `hamroh-base` to exist first.

Claude Code auth is mounted from the host (`~/.claude`), so run `claude login`
on the host once before starting.

## Updating the framework

The framework lives as a git submodule under `framework/`. To bump it to the
latest upstream commit:

```bash
cd framework && git pull origin main && cd ..
git add framework && git commit -m "bump framework"
make up
```

No files to re-copy — `system.md`, `subagents.md`, and the built-in skills are
rebuilt from the bumped submodule automatically.

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
| `memories/` | live (read on demand) |
| `plugins.json`, `default-reminders.json` | on `docker compose restart` |
| `prompts/`, `skills/` (baked) | on rebuild — `make up` |

## What this repo owns

| File / dir | Configures | Git-tracked |
|---|---|---|
| `prompts/project.md` | Persona / system-prompt overlay (baked) | ✅ |
| `skills/` | Your custom skills (baked; framework's are inherited) | ✅ |
| `memories/` | Committed memories the bot reads on demand | ✅ |
| `plugins.json` | Tools + MCP capability surface | ✅ |
| `default-reminders.json` | Scheduled reminders | ✅ |
| `access.json` | Access policy (DM / group) | ✅ |
| `Dockerfile` | Bakes the above onto the framework image | ✅ |
| `.env` | Bot token, owner id, model, MCP secrets | ❌ secrets |
| `data/` | SQLite, runtime memories, logs | ❌ runtime |

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
