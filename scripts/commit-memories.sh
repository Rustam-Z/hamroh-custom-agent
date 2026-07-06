#!/usr/bin/env bash
#
# Commit and push the bot's memory files (`memories/`).
#
# The bot writes memories straight into this repo's checkout on the
# server but never commits them. Uncommitted changes to a memory file
# block `git pull` when the same file changed upstream — which breaks
# updates. `make update` runs this right before `git pull` so the
# checkout is always clean.
#
# When memories were committed, the script rebases on top of the remote
# (the server may be behind) and pushes. `[skip ci]` in the commit
# message keeps the push from triggering CI, should this repo ever get
# a deploy workflow. Safe to run anytime, including via cron.

set -euo pipefail

cd "$(dirname "$0")/.."

git add memories/

if git diff --cached --quiet; then
    echo "No memory changes to commit."
    exit 0
fi

git -c user.name="hamroh" -c user.email="hamroh@localhost" \
    commit -m "memories: sync from server [skip ci]"
git pull --rebase
git push

echo "Memories committed and pushed."
