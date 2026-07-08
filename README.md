# uni-thermos

Portable thermo-nuclear code quality review skill for Codex and Claude Code.

This ports Cursor's `thermo-nuclear-code-quality-review` skill into a standard `SKILL.md` package:

- `thermo-nuclear-code-quality-review/SKILL.md` is the installed skill.
- `thermo-nuclear-code-quality-review/agents/openai.yaml` provides Codex UI metadata.
- `thermo-nuclear-code-quality-review/scripts/spawn-codex-reviewer.sh` lets Claude Code delegate the review to Codex CLI by default.
- `thermo-nuclear-code-quality-review/scripts/update-self.sh` updates installed copies through a source checkout or shallow cache.
- `install.sh` installs the skill into Codex, Claude Code, or both.
- `scripts/validate.sh` validates frontmatter, shell scripts, portability, and install smoke.

Install both targets:

```bash
./install.sh --all --yes
```

Install one target:

```bash
./install.sh --codex
./install.sh --claude
```

Update installed copies from this source checkout:

```bash
./install.sh --update
```

Update from an installed skill:

```bash
${CODEX_HOME:-$HOME/.codex}/skills/thermo-nuclear-code-quality-review/scripts/update-self.sh
~/.claude/skills/thermo-nuclear-code-quality-review/scripts/update-self.sh
```

Use it in Codex:

```text
Use $thermo-nuclear-code-quality-review to review this branch against main.
```

Use it in Claude Code:

```text
/thermo-nuclear-code-quality-review review this branch against main.
```

Claude Code should usually launch a Codex reviewer:

```bash
~/.claude/skills/thermo-nuclear-code-quality-review/scripts/spawn-codex-reviewer.sh \
  --cwd "$PWD" \
  --base main \
  --output ".pstack/workers/thermo-review.md"
```

Validate the package:

```bash
scripts/validate.sh
```

## License and credit

This repository is MIT licensed. See [LICENSE](LICENSE).

This is a portable port of Cursor's MIT-licensed `thermo-nuclear-code-quality-review` skill from `cursor/plugins`. The original source lives at <https://github.com/cursor/plugins/blob/main/cursor-team-kit/skills/thermo-nuclear-code-quality-review/SKILL.md>.
