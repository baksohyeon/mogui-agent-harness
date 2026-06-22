#!/usr/bin/env bash
# install-obsidian-plugins.sh (optional)
# Install the Obsidian community plugins listed in docs/.obsidian/community-plugins.json
# into docs/.obsidian/plugins/<id>/. Optional: only needed if you browse docs/ as an
# Obsidian vault. See docs/wiki/guides/obsidian-setup.md.
#
# Run once, or rerun after editing community-plugins.json. Restart Obsidian after install.

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

command -v jq >/dev/null   || { echo "jq is required (e.g. brew install jq)"; exit 1; }
command -v curl >/dev/null || { echo "curl is required"; exit 1; }

ENABLED_FILE="docs/.obsidian/community-plugins.json"
PLUGINS_DIR="docs/.obsidian/plugins"
REGISTRY_URL="https://raw.githubusercontent.com/obsidianmd/obsidian-releases/HEAD/community-plugins.json"
REGISTRY_CACHE="${TMPDIR:-/tmp}/obsidian-community-plugins.json"

if [[ ! -f "$ENABLED_FILE" ]]; then
  echo "$ENABLED_FILE not found"
  exit 1
fi

# Registry cache (24h)
if [[ ! -f "$REGISTRY_CACHE" ]] || find "$REGISTRY_CACHE" -mmin +1440 2>/dev/null | grep -q .; then
  echo "Fetching Obsidian community plugin registry..."
  curl -fsSL "$REGISTRY_URL" -o "$REGISTRY_CACHE"
fi

PLUGIN_IDS=()
while IFS= read -r line; do
  [[ -n "$line" ]] && PLUGIN_IDS+=("$line")
done < <(jq -r '.[]' "$ENABLED_FILE")

if [[ ${#PLUGIN_IDS[@]} -eq 0 ]]; then
  echo "$ENABLED_FILE is empty. Add plugin IDs and rerun:"
  echo '    Example: ["dataview","templater-obsidian","smart-connections"]'
  exit 0
fi

mkdir -p "$PLUGINS_DIR"

# GitHub API authentication.
# Unauthenticated calls are rate-limited to 60/hr, which 10+ plugin downloads exceed
# immediately. A missing token is a common cause of silent failure, so alert and skip
# explicitly instead of failing halfway.
GH_AUTH=()
if [[ -n "${GITHUB_TOKEN:-}" ]]; then
  GH_AUTH=(-H "Authorization: Bearer ${GITHUB_TOKEN}")
  echo "[GitHub auth] GITHUB_TOKEN detected: rate limit 5000/hr"
else
  echo ""
  echo "================================================================"
  echo "[skip] GITHUB_TOKEN not set: skipping Obsidian plugin install"
  echo "================================================================"
  echo ""
  echo "  Reason: the unauthenticated GitHub API rate limit (60/hr) is"
  echo "          exceeded immediately when downloading ${#PLUGIN_IDS[@]} plugins."
  echo ""
  echo "  How to get a token (1 minute):"
  echo "    1. Open https://github.com/settings/tokens"
  echo "    2. Generate new token (classic), no scopes needed"
  echo "    3. Copy the ghp_... value"
  echo "    4. echo 'export GITHUB_TOKEN=ghp_...' >> ~/.zshrc (or your shell rc)"
  echo "    5. source ~/.zshrc"
  echo ""
  echo "  Then rerun: bash scripts/install-obsidian-plugins.sh"
  echo "  Details: docs/wiki/guides/obsidian-setup.md"
  echo ""
  exit 0
fi

FAIL=0
for ID in "${PLUGIN_IDS[@]}"; do
  echo ""
  echo "Plugin: $ID"
  REPO=$(jq -r --arg id "$ID" '.[] | select(.id == $id) | .repo' "$REGISTRY_CACHE")
  if [[ -z "$REPO" || "$REPO" == "null" ]]; then
    echo "  Not found in registry. Install manually in Obsidian."
    FAIL=$((FAIL+1))
    continue
  fi
  echo "  repo: $REPO"

  RELEASE_JSON=$(curl -fsSL ${GH_AUTH[@]+"${GH_AUTH[@]}"} "https://api.github.com/repos/$REPO/releases/latest" 2>/dev/null || true)
  TAG=$(echo "$RELEASE_JSON" | jq -r '.tag_name // empty')
  if [[ -z "$TAG" ]]; then
    echo "  Could not fetch latest release. If rate-limited, set GITHUB_TOKEN."
    FAIL=$((FAIL+1))
    continue
  fi
  echo "  version: $TAG"

  PLUGIN_DIR="$PLUGINS_DIR/$ID"
  mkdir -p "$PLUGIN_DIR"

  GOT_MAIN=0
  for FILE in main.js manifest.json styles.css; do
    URL=$(echo "$RELEASE_JSON" | jq -r --arg f "$FILE" '.assets[]? | select(.name == $f) | .browser_download_url')
    if [[ -n "$URL" && "$URL" != "null" ]]; then
      curl -fsSL "$URL" -o "$PLUGIN_DIR/$FILE"
      echo "  Installed $FILE"
      [[ "$FILE" == "main.js" ]] && GOT_MAIN=1
    elif [[ "$FILE" == "styles.css" ]]; then
      :  # optional
    else
      echo "  Missing $FILE in this release"
    fi
  done

  if [[ $GOT_MAIN -eq 0 ]]; then
    echo "  main.js not found. This plugin uses a non-standard release; install manually in Obsidian."
    FAIL=$((FAIL+1))
  fi
done

echo ""
if [[ $FAIL -eq 0 ]]; then
  echo "All plugins installed. Restart Obsidian, then verify under Settings -> Community plugins."
else
  echo "Some plugins were installed, but $FAIL failed. Review the messages above."
fi
