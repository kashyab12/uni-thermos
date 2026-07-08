#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
skill_dir="$repo_dir/thermo-nuclear-code-quality-review"
validator="${CODEX_SKILL_VALIDATOR:-/Users/kashyab/.codex/skills/.system/skill-creator/scripts/quick_validate.py}"

fail() {
  printf 'validate.sh: %s\n' "$*" >&2
  exit 1
}

echo "== skill validation =="
[[ -f "$validator" ]] || fail "skill validator not found: $validator"
python3 "$validator" "$skill_dir" >/dev/null
echo "skill validates"

echo "== required files =="
test -f "$skill_dir/SKILL.md"
test -f "$skill_dir/agents/openai.yaml"
test -x "$skill_dir/scripts/spawn-codex-reviewer.sh"
test -x "$skill_dir/scripts/update-self.sh"

echo "== portability scan =="
if rg -n -e '^disable-model-invocation:' -e '^user-invocable:' -e 'subagent_type' -e 'Task\(' "$skill_dir"; then
  fail "found Cursor-only or non-portable skill material"
fi

echo "== shell parse checks =="
bash -n "$repo_dir/install.sh"
bash -n "$skill_dir/scripts/spawn-codex-reviewer.sh"
bash -n "$skill_dir/scripts/update-self.sh"

echo "== installer smoke =="
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
HOME="$tmp/home" CODEX_HOME="$tmp/codex" "$repo_dir/install.sh" --all --yes >/tmp/uni-thermos-install.log
HOME="$tmp/home" CODEX_HOME="$tmp/codex" "$repo_dir/install.sh" --update >/tmp/uni-thermos-update.log
HOME="$tmp/home" CODEX_HOME="$tmp/codex" "$skill_dir/scripts/update-self.sh" --source "$repo_dir" --dry-run >/tmp/uni-thermos-self-update.log
test -f "$tmp/codex/skills/thermo-nuclear-code-quality-review/SKILL.md"
test -x "$tmp/codex/skills/thermo-nuclear-code-quality-review/scripts/spawn-codex-reviewer.sh"
test -x "$tmp/codex/skills/thermo-nuclear-code-quality-review/scripts/update-self.sh"
test -f "$tmp/home/.claude/skills/thermo-nuclear-code-quality-review/SKILL.md"
test -x "$tmp/home/.claude/skills/thermo-nuclear-code-quality-review/scripts/spawn-codex-reviewer.sh"
test -x "$tmp/home/.claude/skills/thermo-nuclear-code-quality-review/scripts/update-self.sh"
rg -q 'installed Codex' /tmp/uni-thermos-install.log
rg -q 'installed Claude Code' /tmp/uni-thermos-install.log
rg -q 'Mode: update installed copies' /tmp/uni-thermos-update.log
rg -q 'would install Codex' /tmp/uni-thermos-self-update.log

echo "validation passed"
