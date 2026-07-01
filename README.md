# luna

A persona instance of the [hamroh](https://github.com/Rustam-Z/hamroh)
framework. hamroh is pinned as a git submodule under `framework/`; this repo
owns only Luna's identity — persona, skills, memories, MCP config, reminders,
and access. No framework code is forked, so `git pull` in the submodule keeps
the engine up to date.

## How it works

Two layers:

- **`framework/`** — the hamroh engine, pinned as a git submodule to one exact
  commit. It ships the Docker image, the base system prompt, the built-in
  skills, and all the Python. You never edit it.
- **This repo** — Luna's identity as plain files. At `docker compose up`,
  Docker builds the image from `framework/` (`build: ./framework`) and
  **bind-mounts** these files over it, so the running container is the engine
  wearing Luna's config.

```
docker image (from framework/)          your files, mounted on top
├── /app/hamroh          (engine)  ◄──  (untouched)
├── /app/prompts/system.md         ◄──  ./prompts/  (system.md + project.md)
├── /app/skills/         (built-in) ◄─  ./skills/
├── /app/plugins.json              ◄──  ./plugins.json
├── /app/access.json               ◄──  ./access.json
├── /app/default-reminders.json    ◄──  ./default-reminders.json
└── /app/memories/                 ◄──  ./memories/
```

**One gotcha worth knowing:** a directory bind-mount *masks* what the image
baked at that path — it replaces, it doesn't merge. So `./prompts` and
`./skills` hide the image's own `system.md` and built-in skills. That's why
both are **seeded from the framework** into this repo (see
[Updating the framework](#updating-the-framework)); drop those files and the
bot loses its base prompt and playbooks. `memories/` has nothing baked, so its
mount only adds.

Config is read at different times: `access.json` is hot-reloaded, `memories/`
is read on demand (live), while `plugins.json`, `default-reminders.json`, and
the prompts are read at boot — so those need a `docker compose restart`.

## What this repo owns

| File / dir | Configures | Git-tracked |
|---|---|---|
| `prompts/project.md` | Persona / system-prompt overlay | ✅ |
| `prompts/system.md` | Framework base prompt (seeded — required) | ✅ |
| `skills/` | Framework playbooks (seeded) + Luna's own | ✅ |
| `memories/` | Committed memories the bot reads on demand | ✅ |
| `plugins.json` | Tools + MCP capability surface | ✅ |
| `default-reminders.json` | Scheduled reminders | ✅ |
| `access.json` | Access policy (DM / group) | ✅ |
| `.env` | Bot token, owner id, model, MCP secrets | ❌ secrets |
| `data/` | SQLite, runtime memories, logs | ❌ runtime |

`access.json` is tracked as the source of truth. Owner commands `/allow`,
`/deny`, `/dmpolicy` edit it live on the host, so after using them commit the
change to persist it — or just edit the file and `docker compose restart`.

## Setup

```bash
git clone --recurse-submodules https://github.com/Rustam-Z/luna && cd luna
# already cloned without --recurse-submodules?
git submodule update --init

cp .env.example .env               # set TELEGRAM_BOT_TOKEN, HAMROH_OWNER_ID, HAMROH_MODEL

docker compose up -d --build
docker compose logs -f luna
```

Claude Code auth is mounted from the host (`~/.claude`), so run `claude login`
on the host once before starting.

## Customizing

- **Persona** → edit `prompts/project.md`.
- **MCPs** → in `plugins.json` set an MCP `"enabled": true` and add its secret
  to `.env`. See `framework/docs/tools.md`.
- **Reminders** → add entries to `default-reminders.json`.
- **Skills** → drop a `skills/<name>/SKILL.md` folder.
- **Memories** → add `memories/**/*.md` with `name` + `description` frontmatter.

## Updating the framework

```bash
cd framework && git pull origin main && cd ..
cp framework/prompts/system.md prompts/system.md   # re-seed baked files
cp -R framework/skills/. skills/
git add framework prompts skills
git commit -m "bump framework"
docker compose up -d --build
```

## Installing extra packages

Need a system binary or extra Python dep? Don't edit `framework/`. Add a
`Dockerfile` here that builds on top, point compose at it (`build: .` instead
of `build: ./framework`), and use a two-step build. See
`framework/docs/documentation.md#installing-extra-packages`.
