#!/usr/bin/env bash
#
# Commit and push ALL local changes in this server checkout, then update.
#
# The bot writes its own state straight into this repo's checkout on the
# server: memories/ and prompts/project.md are bind-mounted read-write,
# and the agent may also edit other tracked files (e.g. access.json).
# Any uncommitted change to a file that also changed upstream blocks
# `git pull` and breaks updates. To keep the checkout always pullable we
# commit everything here.
#
# `git add -A` respects .gitignore, so secrets (.env) and host-only
# runtime data (data/, memories/self/) are never committed — only
# tracked files are.
#
# When there is something to commit, the script rebases on top of the
# remote (the server may be behind) and pushes. `[skip ci]` in the commit
# message keeps the push from triggering CI, should this repo ever get a
# deploy workflow. Safe to run anytime, including via cron. `make update`
# runs this right before `git pull`.

set -euo pipefail

cd "$(dirname "$0")/.."

git add -A

if git diff --cached --quiet; then
    echo "No local changes to commit."
    exit 0
fi

git -c user.name="hamroh" -c user.email="hamroh@localhost" \
    commit -m "sync server state [skip ci]"
git pull --rebase
git push

echo "Local changes committed and pushed."
