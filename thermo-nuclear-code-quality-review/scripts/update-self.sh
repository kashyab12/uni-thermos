#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  update-self.sh [install options]

Update installed thermo-nuclear-code-quality-review skills.

By default, when run from an installed skill, this script keeps a shallow source
checkout at ${XDG_CACHE_HOME:-$HOME/.cache}/uni-thermos/source and runs:

  ./install.sh --update

Options handled here:
  --source DIR            Use an existing uni-thermos source checkout.
  --repo URL              Git URL for the cache checkout.
                          Default: https://github.com/kashyab12/uni-thermos.git
  --ref REF               Branch, tag, or commit to fetch for the cache checkout.
                          Default: main
  --skip-fetch            Use the existing source checkout without fetching.
  -h, --help              Show this help.

All other options are passed to install.sh. Common examples:

  thermo-nuclear-code-quality-review/scripts/update-self.sh
  thermo-nuclear-code-quality-review/scripts/update-self.sh --codex
  thermo-nuclear-code-quality-review/scripts/update-self.sh --claude
  thermo-nuclear-code-quality-review/scripts/update-self.sh --dry-run
USAGE
}

die() {
  printf 'update-self.sh: %s\n' "$*" >&2
  exit 1
}

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_url="${UNI_THERMOS_REPO_URL:-https://github.com/kashyab12/uni-thermos.git}"
ref="${UNI_THERMOS_REF:-main}"
source_dir="${UNI_THERMOS_SOURCE_DIR:-}"
skip_fetch=0
install_args=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source)
      source_dir="${2:?missing source directory}"
      shift 2
      ;;
    --repo)
      repo_url="${2:?missing repository URL}"
      shift 2
      ;;
    --ref)
      ref="${2:?missing ref}"
      shift 2
      ;;
    --skip-fetch)
      skip_fetch=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      install_args+=("$1")
      shift
      ;;
  esac
done

candidate_repo="$(cd "$script_dir/../.." && pwd)"
if [[ -z "$source_dir" && -f "$candidate_repo/install.sh" && -f "$candidate_repo/thermo-nuclear-code-quality-review/SKILL.md" ]]; then
  source_dir="$candidate_repo"
fi

if [[ -z "$source_dir" && -f "$PWD/install.sh" && -f "$PWD/thermo-nuclear-code-quality-review/SKILL.md" ]]; then
  source_dir="$PWD"
fi

if [[ -z "$source_dir" ]]; then
  cache_root="${XDG_CACHE_HOME:-$HOME/.cache}/uni-thermos"
  source_dir="$cache_root/source"
  mkdir -p "$cache_root"

  if [[ ! -d "$source_dir/.git" ]]; then
    git clone --depth=1 --filter=blob:none --branch "$ref" "$repo_url" "$source_dir"
  elif [[ "$skip_fetch" -eq 0 ]]; then
    git -C "$source_dir" remote set-url origin "$repo_url"
    git -C "$source_dir" fetch --depth=1 origin "$ref"
    git -C "$source_dir" checkout -q FETCH_HEAD
  fi
elif [[ "$source_dir" != /* ]]; then
  source_dir="$(cd "$source_dir" && pwd)"
fi

[[ -f "$source_dir/install.sh" ]] || die "missing install.sh in source checkout: $source_dir"
[[ -f "$source_dir/thermo-nuclear-code-quality-review/SKILL.md" ]] || die "missing skill in source checkout: $source_dir"

printf 'Updating uni-thermos from: %s\n' "$source_dir" >&2
"$source_dir/install.sh" --update "${install_args[@]}"
