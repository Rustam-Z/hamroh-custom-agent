# luna

A persona instance of the [hamroh](https://github.com/Rustam-Z/hamroh)
framework. hamroh is pinned as a git submodule under `framework/`; this repo
owns only Luna's identity — persona, skills, memories, MCP config, reminders,
and access. No framework code is forked, so `git pull` in the submodule keeps
the engine up to date.

## What this repo owns

| File / dir | Configures | Git-tracked |
|---|---|---|
| `prompts/project.md` | Persona / system-prompt overlay | ✅ |
| `prompts/system.md` | Framework base prompt (seeded — required) | ✅ |
| `skills/` | Framework playbooks (seeded) + Luna's own | ✅ |
| `memories/` | Committed memories the bot reads on demand | ✅ |
| `plugins.json` | Tools + MCP capability surface | ✅ |
| `default-reminders.json` | Scheduled reminders | ✅ |
| `access.json.example` | Access policy template | ✅ |
| `.env` | Bot token, owner id, model, MCP secrets | ❌ secrets |
| `access.json` | Live access policy (mutated by `/allow`, `/deny`) | ❌ runtime |
| `data/` | SQLite, runtime memories, logs | ❌ runtime |

## Setup

```bash
git clone --recurse-submodules https://github.com/Rustam-Z/luna && cd luna
# already cloned without --recurse-submodules?
git submodule update --init

cp .env.example .env               # set TELEGRAM_BOT_TOKEN, HAMROH_OWNER_ID, HAMROH_MODEL
cp access.json.example access.json # live policy (gitignored; edited by /allow, /deny)

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
