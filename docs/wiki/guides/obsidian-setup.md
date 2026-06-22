---
id: guide-obsidian-setup
title: "Obsidian Setup (optional)"
type: guide
created_at: YYYY-MM-DD
created_by: "@git_author"
updated_at: YYYY-MM-DD
updated_by: "@git_author"
last_verified_at: YYYY-MM-DD
last_verified_by: "@git_author"
audit_log:
  - action: created
    at: YYYY-MM-DD
    by: "@git_author"
    note: "Optional Obsidian vault setup for browsing docs/."
status: active
tags: [guide, obsidian, optional]
relations: []
code_refs: []
---

# Obsidian Setup (optional)

This is optional. The wiki under `docs/` is plain Markdown and works in any editor. Obsidian just gives you a nicer way to browse it: backlinks, graph view, and similar-note suggestions over the same files. Skip this whole guide if you do not use Obsidian.

## What it is

- **Obsidian**: a free local Markdown app (macOS/Windows/Linux). It never uploads your files. See [obsidian.md](https://obsidian.md).
- **vault**: the folder Obsidian opens as one knowledge base. Here the vault root is `docs/`.
- This complements the layer split in [Agentic Architecture](./02-agentic-architecture.md): `docs/wiki/` is the human-read knowledge layer, and Obsidian is one way to read it.

## Setup

1. Install Obsidian.
2. Open `docs/` as a vault (Open folder as vault).
3. (Optional) Install the recommended community plugins listed in `docs/.obsidian/community-plugins.json`:

   ```bash
   bash scripts/install-obsidian-plugins.sh
   ```

   This needs `jq`, `curl`, and a `GITHUB_TOKEN` (any classic token, no scopes) to avoid the GitHub API rate limit. The script prints the steps if the token is missing.
4. Restart Obsidian and enable the plugins under Settings, Community plugins.

## Recommended plugins

| Plugin | Why |
|---|---|
| Dataview | Render frontmatter fields as queryable tables (for example a live decisions index). |
| Templater | Auto-fill new notes from templates (date, id, frontmatter). |
| Smart Connections | Suggest similar notes using local embeddings (no external API call). |
| Linter | Normalize Markdown and frontmatter on save. |
| Breadcrumbs | Navigate parent/child relations between notes. |

Edit `docs/.obsidian/community-plugins.json` to add or remove plugins, then rerun the script.

## Notes

- Personal UI state (`docs/.obsidian/workspace.json`, window layout, themes) is yours to keep local; this starter only ships the plugin list.
- Obsidian is a viewer. The source of truth is the Markdown files and their frontmatter, not anything Obsidian stores.
