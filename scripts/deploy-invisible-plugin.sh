#!/usr/bin/env bash
# Deploy InvisiblePlugin from its source repo into custom_files/.
#
# custom_files/ is merged over the CS2 install on every container start
# (install_docker.sh: cp -RT /home/custom_files/ /home/steam/cs2/game/csgo/),
# so anything here survives upstream syncs of the bundled game/ tree.
#
# Usage:  scripts/deploy-invisible-plugin.sh [/path/to/InvisiblePlugin]
# Default plugin repo path: ../../InvisiblePlugin (workspace layout).
#
# What lands where:
#   custom_files/addons/counterstrikesharp/plugins/InvisiblePlugin/   <- publish output
#   custom_files/addons/counterstrikesharp/gamedata/InvisiblePlugin.gamedata.json
#
# CounterStrikeSharp.API.dll is deliberately NOT copied: the bundled
# CounterStrikeSharp host provides the API assembly (bundled plugins ship
# without it too; a local copy would shadow the host's).

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PLUGIN_REPO="${1:-$REPO_ROOT/../../InvisiblePlugin}"
PLUGIN_REPO="$(cd "$PLUGIN_REPO" && pwd)"

PUBLISH_TMP="$(mktemp -d)"
trap 'rm -rf "$PUBLISH_TMP"' EXIT

echo "Publishing $PLUGIN_REPO (Release)..."
dotnet publish "$PLUGIN_REPO/InvisiblePlugin.csproj" -c Release -o "$PUBLISH_TMP"

PLUGIN_DIR="$REPO_ROOT/custom_files/addons/counterstrikesharp/plugins/InvisiblePlugin"
GAMEDATA_DIR="$REPO_ROOT/custom_files/addons/counterstrikesharp/gamedata"

mkdir -p "$PLUGIN_DIR" "$GAMEDATA_DIR"

echo "Copying plugin files to custom_files/..."
for entry in "$PUBLISH_TMP"/*; do
    name="$(basename "$entry")"
    [ "$name" = "CounterStrikeSharp.API.dll" ] && continue
    cp -r "$entry" "$PLUGIN_DIR/"
done

echo "Copying gamedata..."
cp "$PLUGIN_REPO/gamedata/InvisiblePlugin.gamedata.json" "$GAMEDATA_DIR/"

echo "Deployed:"
find "$REPO_ROOT/custom_files/addons/counterstrikesharp" -maxdepth 3 -name "*nvisible*" -o -maxdepth 3 -name "InvisiblePlugin.gamedata.json" | sort
