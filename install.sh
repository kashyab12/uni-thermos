#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  ./install.sh [targets] [options]

Targets:
  --codex                 Install to Codex user skills.
  --claude                Install to Claude Code user skills.
  --all                   Install to both Codex and Claude Code.

Options:
  --update                Update installed copies from this repo. Equivalent to
                          --all --force --yes when no target is supplied.
  --codex-dir DIR         Default: ${CODEX_HOME:-$HOME/.codex}/skills
  --claude-dir DIR        Default: $HOME/.claude/skills
  --force                 Replace an existing installed copy.
  --yes                   Non-interactive. Defaults to both targets.
  --dry-run               Print actions without writing files.
  -h, --help              Show help.

Examples:
  ./install.sh
  ./install.sh --update
  ./install.sh --update --codex
  ./install.sh --all --force
USAGE
}

install_codex=0
install_claude=0
target_supplied=0
force=0
assume_yes=0
dry_run=0
update=0

codex_dir="${CODEX_HOME:-$HOME/.codex}/skills"
claude_dir="$HOME/.claude/skills"

die() {
  printf 'install.sh: %s\n' "$*" >&2
  exit 1
}

is_interactive() {
  [[ -t 0 && -t 1 && "$assume_yes" -eq 0 ]]
}

abs_dir() {
  local input="$1"
  if [[ -d "$input" ]]; then
    (cd "$input" && pwd)
  elif [[ "$input" = /* ]]; then
    printf '%s\n' "$input"
  else
    printf '%s/%s\n' "$(pwd)" "$input"
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --codex)
      install_codex=1
      target_supplied=1
      shift
      ;;
    --claude)
      install_claude=1
      target_supplied=1
      shift
      ;;
    --all)
      install_codex=1
      install_claude=1
      target_supplied=1
      shift
      ;;
    --codex-dir)
      codex_dir="${2:?missing Codex skills directory}"
      shift 2
      ;;
    --claude-dir)
      claude_dir="${2:?missing Claude Code skills directory}"
      shift 2
      ;;
    --force)
      force=1
      shift
      ;;
    --update)
      update=1
      force=1
      assume_yes=1
      shift
      ;;
    --yes|-y)
      assume_yes=1
      shift
      ;;
    --dry-run)
      dry_run=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
skill_src="$repo_dir/thermo-nuclear-code-quality-review"

[[ -f "$skill_src/SKILL.md" ]] || die "missing skill at $skill_src"

if [[ "$target_supplied" -eq 0 ]]; then
  if [[ "$update" -eq 1 ]]; then
    install_codex=1
    install_claude=1
  elif is_interactive; then
    echo "Install thermo-nuclear-code-quality-review."
    echo
    echo "Targets:"
    echo "  1. Codex       -> $codex_dir"
    echo "  2. Claude Code -> $claude_dir"
    echo
    printf 'Install targets [both/codex/claude/none] (both): '
    IFS= read -r answer
    answer="${answer:-both}"
    case "$(printf '%s' "$answer" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')" in
      both|all|1,2|2,1|"")
        install_codex=1
        install_claude=1
        ;;
      codex|1)
        install_codex=1
        ;;
      claude|claudecode|2)
        install_claude=1
        ;;
      none|no|n|cancel)
        ;;
      *)
        die "unknown target selection: $answer"
        ;;
    esac
  else
    install_codex=1
    install_claude=1
  fi
fi

confirm_replace() {
  local dest="$1"
  local answer
  if [[ "$force" -eq 1 || "$assume_yes" -eq 1 ]]; then
    return 0
  fi
  if ! is_interactive; then
    return 1
  fi
  printf 'Replace existing install at %s? [y/N]: ' "$dest"
  IFS= read -r answer
  [[ "$(printf '%s' "$answer" | tr '[:upper:]' '[:lower:]')" == "y" || "$(printf '%s' "$answer" | tr '[:upper:]' '[:lower:]')" == "yes" ]]
}

copy_skill() {
  local label="$1"
  local root="$2"
  local abs_root
  local abs_src
  local dest
  abs_root="$(abs_dir "$root")"
  abs_src="$(cd "$skill_src" && pwd)"
  dest="$abs_root/$(basename "$skill_src")"

  if [[ "$dest" == "$abs_src" ]]; then
    echo "$label already points at source: $dest"
    return 0
  fi

  if [[ "$dry_run" -eq 1 ]]; then
    echo "would install $label: $abs_src -> $dest"
    return 0
  fi

  mkdir -p "$abs_root"
  if [[ -e "$dest" ]]; then
    if ! confirm_replace "$dest"; then
      die "$label destination exists: $dest (use --force to replace)"
    fi
    rm -rf "$dest"
  fi

  cp -R "$abs_src" "$dest"
  echo "installed $label: $dest"
}

if [[ "$install_codex" -eq 0 && "$install_claude" -eq 0 ]]; then
  echo "No install targets selected."
  exit 0
fi

echo "Source: $repo_dir"
if [[ "$update" -eq 1 ]]; then
  echo "Mode: update installed copies"
fi
if [[ "$install_codex" -eq 1 ]]; then
  copy_skill "Codex" "$codex_dir"
fi
if [[ "$install_claude" -eq 1 ]]; then
  copy_skill "Claude Code" "$claude_dir"
fi

echo
echo "Next:"
if [[ "$install_codex" -eq 1 ]]; then
  echo "  Codex: start a new session, then use: Use \$thermo-nuclear-code-quality-review to review this branch."
fi
if [[ "$install_claude" -eq 1 ]]; then
  echo "  Claude Code: restart or reload, then use: /thermo-nuclear-code-quality-review review this branch."
fi
