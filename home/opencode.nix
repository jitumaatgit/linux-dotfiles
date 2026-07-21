{ ... }:

{
  # opencode CLI config — ported from the Windows ~/.config/opencode/.
  # HM manages the JSON config + slash commands + modes. Skills and
  # AGENTS.md stay user-managed (see "Not HM-managed" below).
  #
  # The opencode binary itself is NOT installed by HM — it is a Node
  # CLI installed out-of-band (`npm i -g opencode` or the user's
  # bootstrap). HM only writes the config files it reads.
  #
  # Windows→Linux port: the opencode.json has no Windows paths to
  # replace (it is path-free — provider block + model picks). The
  # command/mode files are markdown with no OS-specific paths either.
  # Path-rewriting concerns that applied to nvim/wezterm/ntfy do not
  # apply here; the port is content-identical modulo Windows→Linux
  # newline normalization (CRLF→LF) and a trailing-newline added to
  # opencode.jsonc for POSIX compliance (the Windows source had none).
  #
  # `command/` (singular) on Windows is non-canonical — opencode reads
  # `commands/` (plural). The 3 files unique to `command/` (commit.md,
  # learn.md, rmslop.md) are merged into `commands/` here. The
  # plannotator-* files were identical in both dirs (verified by diff)
  # so no content is lost.
  #
  # Not HM-managed (left for the user / opencode itself to manage):
  #   - ~/.config/opencode/AGENTS.md      — OS-specific, hand-edited
  #   - ~/.config/opencode/skills/        — `npx skills add` targets
  #                                         ~/.agents/skills/ (user-level,
  #                                         per the ticket); the config-
  #                                         level skills/ dir is left empty
  #   - ~/.config/opencode/package.json   — opencode regenerates when
  #                                         plugins/MCP servers are installed
  #   - ~/.config/opencode/node_modules/  — npm install output
  #   - ~/.config/opencode/.gitignore     — HM is the source of truth,
  #                                         no per-dir git tracking needed

  # Provider block (NVIDIA NIM) + model picks. Ported verbatim — no
  # Windows paths. `{env:NVIDIA_API_KEY}` is opencode's templating
  # (not Nix interpolation — `${` triggers Nix, `{env:` does not).
  xdg.configFile."opencode/opencode.json".text = ''
{
  "$schema": "https://opencode.ai/config.json",
  "provider": {
    "nvidia": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "NVIDIA NIM",
      "options": {
        "baseURL": "https://integrate.api.nvidia.com/v1",
        "apiKey": "{env:NVIDIA_API_KEY}"
      },
      "models": {
        "z-ai/glm-5.2": {
          "name": "GLM 5.1"
        },
        "moonshotai/kimi-k2.6": {
          "name": "Kimi K2.6"
        },
        "minimaxai/minimax-m2.7": {
          "name": "MiniMax M2.7"
        },
        "minimaxai/minimax-m3": {
          "name": "MiniMax M3"
        }
      }
    }
  },
  "model": "nvidia/z-ai/glm-5.2",
  "small_model": "nvidia/minimaxai/minimax-m3",
  "agent": {
    "build": {
      "model": "nvidia/minimaxai/minimax-m3"
    }
  }
}
'';

  # JSONC variant — schema-ref-only file. Ported content-identical
  # (trailing newline added for POSIX compliance; see header note).
  xdg.configFile."opencode/opencode.jsonc".text = ''
{
  "$schema": "https://opencode.ai/config.json"
}
'';

  # Slash commands — ported from Windows commands/ + the 3 unique
  # files from command/. `$ARGUMENTS` is opencode's literal template
  # var (not Nix interpolation — `$A` not `${`). Backticks and `!` in
  # commit.md are opencode's command-substitution syntax, literal.

  xdg.configFile."opencode/commands/commit.md".text = ''
---
description: git commit and push using scoped commits
subtask: true
---

commit and push using Scoped Commits (https://scopedcommits.com).

format: `<scope>: <description>` with optional body and trailers. keep the
description under 72 chars, imperative mood ("add" not "added").

scope = the subsystem, area, or module this commit touches. it is required and
goes first. derive it from the diff — the files and areas actually changed —
not from a fixed list. never use a conventional-commit type as the prefix (no
`feat`, `fix`, `chore`, `docs`, `refactor`, etc.); the description already
conveys the type.

multiple scopes: use a more general scope that covers them, list them
comma-separated, or use `treewide` / `all` / `global` if the whole tree is
touched. reverts, merges, and other special commits may be free-form.

ticket numbers (if any): put in parentheses after the scope, e.g.
`auth (PROJ-123): fix login`, or in a trailer.

prefer to explain WHY from an end-user perspective instead of WHAT was done.
be specific about user-facing changes — no generic messages like "improved
agent experience".

## staging

stage specific files, never `git add -A` or `git add .` blindly. if the diff
contains multiple unrelated logical changes, split into separate scoped
commits — one logical change per commit — instead of one mega-commit.

never commit secrets (.env, credentials, private keys, api tokens). if any
staged file looks like a secret, stop and notify me before proceeding.

## safety

- never update git config.
- never skip hooks (`--no-verify`) unless I explicitly ask.
- never force-push to main/master.
- if a commit fails due to hooks, fix the issue and create a NEW commit — do
  not amend the failed one.

## conflicts

if there are conflicts, fix them automatically by loading the
`resolving-merge-conflicts` skill and following its workflow. always notify me
of what was resolved, even on success — do not silently auto-resolve. only
escalate (stop and ask) if the conflicts cannot be resolved confidently.

## report

after commit and push, return a compact one-line report per commit:
`<short-sha> <scope>: <description> (<files-changed-count>)`. no verbose
narration.

$ARGUMENTS

## GIT DIFF

!`git diff`

## GIT DIFF --cached

!`git diff --cached`

## GIT STATUS --short

!`git status --short`
'';

  xdg.configFile."opencode/commands/learn.md".text = ''
---
description: Extract non-obvious learnings from session to AGENTS.md files to build codebase understanding
---

Analyze this session and extract non-obvious learnings to add to AGENTS.md files.

AGENTS.md files can exist at any directory level, not just the project root. When an agent reads a file, any AGENTS.md in parent directories are automatically loaded into the context of the tool read. Place learnings as close to the relevant code as possible:

- Project-wide learnings → root AGENTS.md
- Package/module-specific → packages/foo/AGENTS.md
- Feature-specific → src/auth/AGENTS.md

What counts as a learning (non-obvious discoveries only):

- Hidden relationships between files or modules
- Execution paths that differ from how code appears
- Non-obvious configuration, env vars, or flags
- Debugging breakthroughs when error messages were misleading
- API/tool quirks and workarounds
- Build/test commands not in README
- Architectural decisions and constraints
- Files that must change together

What NOT to include:

- Obvious facts from documentation
- Standard language/framework behavior
- Things already in an AGENTS.md
- Verbose explanations
- Session-specific details

Process:

1. Review session for discoveries, errors that took multiple attempts, unexpected connections
2. Determine scope - what directory does each learning apply to?
3. Read existing AGENTS.md files at relevant levels
4. Create or update AGENTS.md at the appropriate level
5. Keep entries to 1-3 lines per insight

After updating, summarize which AGENTS.md files were created/updated and how many learnings per file.

$ARGUMENTS
'';

  xdg.configFile."opencode/commands/rmslop.md".text = ''
---
description: Remove AI code slop
---

Check the diff against dev, and remove all AI generated slop introduced in this branch.

This includes:

- Extra comments that a human wouldn't add or is inconsistent with the rest of the file
- Extra defensive checks or try/catch blocks that are abnormal for that area of the codebase (especially if called by trusted / validated codepaths)
- Casts to any to get around type issues
- Any other style that is inconsistent with the file
- Unnecessary emoji usage

Report at the end with only a 1-3 sentence summary of what you changed
'';

  xdg.configFile."opencode/commands/plannotator-annotate.md".text = ''
---
description: Open interactive annotation UI for a markdown file
---

The Plannotator Annotate has been triggered. Opening the annotation UI...
Acknowledge "Opening annotation UI..." and wait for the user's feedback.
'';

  xdg.configFile."opencode/commands/plannotator-last.md".text = ''
---
description: Annotate the last assistant message
---
'';

  xdg.configFile."opencode/commands/plannotator-review.md".text = ''
---
description: Open interactive code review for current changes
---

The Plannotator Code Review has been triggered. Opening the review UI...
Acknowledge "Opening code review..." and wait for the user's feedback.
'';

  # Modes — ported verbatim. The `#38A3EE` hex color is literal (`#`
  # is only a Nix comment outside strings).
  xdg.configFile."opencode/modes/docs.md".text = ''
---
description: ALWAYS use this when writing docs
color: "#38A3EE"
---

You are an expert technical documentation writer

You are not verbose

Use a relaxed and friendly tone

The title of the page should be a word or a 2-3 word phrase

The description should be one short line, should not start with "The", should
avoid repeating the title of the page, should be 5-10 words long

Chunks of text should not be more than 2 sentences long

Each section is separated by a divider of 3 dashes

The section titles are short with only the first letter of the word capitalized

The section titles are in the imperative mood

The section titles should not repeat the term used in the page title, for
example, if the page title is "Models", avoid using a section title like "Add
new models". This might be unavoidable in some cases, but try to avoid it.

Check out the /packages/web/src/content/docs/docs/index.mdx as an example.

For JS or TS code snippets remove trailing semicolons and any trailing commas
that might not be needed.

If you are making a commit prefix the commit message with `docs:`
'';
}
