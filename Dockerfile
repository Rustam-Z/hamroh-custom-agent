# Luna = the hamroh framework image + Luna's identity baked on top.
# The base image (hamroh-base) must be built first from the submodule:
#   docker build -t hamroh-base ./framework
# `make up` does that step for you, then builds this.
FROM hamroh-base

# Persona overlay (this repo). COPY merges into the baked prompts dir, so the
# framework's system.md stays intact — no masking, no seeding.
COPY prompts/project.md /app/prompts/project.md

# The subagents doc isn't baked into the base image; pull it straight from the
# pinned framework source so it's always the matching version. Only read when
# subagents are enabled in plugins.json.
COPY framework/prompts/subagents.md /app/prompts/subagents.md

# Custom skills merge onto the baked framework skills (none yet — drop
# skills/<name>/SKILL.md folders here and rebuild).
COPY skills/ /app/skills/
