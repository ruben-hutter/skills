#!/usr/bin/env sh
# Idempotent installer for the pi subagent kit.
# Symlinks the bundled example extension into the pi config dir, deploys the
# agent templates, and wires up the workflow prompt templates.
set -eu

PI_HOME="${PI_HOME:-$HOME/.pi/agent}"
RELEASES_DIR="$PI_HOME/install/releases"

# Newest installed release wins; sort -V handles multi-digit versions.
release="$(find "$RELEASES_DIR" -maxdepth 1 -mindepth 1 -type d | sort -V | tail -n 1)"
if [ -z "$release" ]; then
  echo "error: no pi releases found under $RELEASES_DIR" >&2
  exit 1
fi
example="$release/node_modules/@earendil-works/pi-coding-agent/examples/extensions/subagent"
if [ ! -f "$example/index.ts" ]; then
  echo "error: example subagent extension not found at $example" >&2
  exit 1
fi
echo "Using pi release: $(basename "$release")"

mkdir -p "$PI_HOME/extensions/subagent" "$PI_HOME/agents" "$PI_HOME/prompts"

# Extension code tracks upstream (do not copy locally unless patching).
ln -sfn "$example/index.ts"  "$PI_HOME/extensions/subagent/index.ts"
ln -sfn "$example/agents.ts" "$PI_HOME/extensions/subagent/agents.ts"

# Agent definitions are deployed state: copy templates, never overwrite edits.
here="$(cd "$(dirname "$0")" && pwd)"
for f in "$here"/templates/*.md; do
  name="$(basename "$f")"
  target="$PI_HOME/agents/$name"
  if [ -f "$target" ] && ! cmp -s "$f" "$target"; then
    echo "Skipping $target (already exists and differs; edit it or remove it to redeploy)"
  else
    cp "$f" "$target"
    echo "Deployed $target"
  fi
done

# Workflow prompts are stock upstream files: symlink so they track the release.
for p in implement.md scout-and-plan.md implement-and-review.md; do
  ln -sfn "$example/prompts/$p" "$PI_HOME/prompts/$p"
  echo "Linked $PI_HOME/prompts/$p"
done

echo "Done. Start a new pi session and check the subagent tool's agent list."
