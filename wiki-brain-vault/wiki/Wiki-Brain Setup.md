# Wiki-Brain Setup

How this vault is wired (per `C:\Dev\wiki-brain-setup-guide.md`).

- `wiki-brain-vault/wiki/` — Claude-owned pages; entry point `wiki/index.md`.
- `wiki-brain-vault/raw/` — immutable sources (currently the Claude Design export). Never edited.
- `wiki-brain-vault/log.md` — append-only session journal: `## [YYYY-MM-DD HH:MM] session | title` + `Touched:` line.
- Repo-root `CLAUDE.md` has the "Wiki-Brain" block that makes every session read + maintain the vault.
- `.gitignore` excludes `wiki-brain-vault/graphify-out/`.
- Opens as an Obsidian vault (`[[Page]]` links).

## Updating
New durable knowledge → create/update a page, link it from related pages, add it to `index.md`, log line.
Contradictions with existing pages → surface to the user, don't silently overwrite.

Links: [[CLAUDE.md Rules]], [[Relay Translate]]
