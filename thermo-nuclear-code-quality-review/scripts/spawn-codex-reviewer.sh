#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  spawn-codex-reviewer.sh [--cwd DIR] [--base BRANCH] [--target uncommitted|base]
                          [--output FILE] [--model MODEL] [--reasoning low|medium|high|xhigh]
                          [--service-tier TIER] [--background] [--json]
                          [--log FILE] [--pid-file FILE] [--prompt TEXT]

Defaults:
  target:       base
  base:         main
  model:        THERMO_CODEX_MODEL or PSTACK_CODEX_MODEL or gpt-5.5
  reasoning:    THERMO_CODEX_REASONING or PSTACK_CODEX_REASONING or high
  service tier: THERMO_CODEX_SERVICE_TIER or PSTACK_CODEX_SERVICE_TIER or fast
USAGE
}

cwd="$PWD"
base="main"
target="base"
output=""
model="${THERMO_CODEX_MODEL:-${PSTACK_CODEX_MODEL:-gpt-5.5}}"
reasoning="${THERMO_CODEX_REASONING:-${PSTACK_CODEX_REASONING:-high}}"
service_tier="${THERMO_CODEX_SERVICE_TIER:-${PSTACK_CODEX_SERVICE_TIER:-fast}}"
background=0
json=0
log_file=""
pid_file=""
extra_prompt=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --cwd)
      cwd="${2:?missing cwd}"
      shift 2
      ;;
    --base)
      base="${2:?missing base branch}"
      shift 2
      ;;
    --target)
      target="${2:?missing target}"
      shift 2
      ;;
    --output)
      output="${2:?missing output file}"
      shift 2
      ;;
    --model)
      model="${2:?missing model}"
      shift 2
      ;;
    --reasoning)
      reasoning="${2:?missing reasoning}"
      shift 2
      ;;
    --service-tier)
      service_tier="${2:?missing service tier}"
      shift 2
      ;;
    --background)
      background=1
      shift
      ;;
    --json)
      json=1
      shift
      ;;
    --log)
      log_file="${2:?missing log file}"
      shift 2
      ;;
    --pid-file)
      pid_file="${2:?missing pid file}"
      shift 2
      ;;
    --prompt)
      extra_prompt="${2:?missing prompt}"
      shift 2
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

case "$target" in
  base|uncommitted)
    ;;
  *)
    echo "target must be base or uncommitted" >&2
    exit 2
    ;;
esac

if ! command -v codex >/dev/null 2>&1; then
  echo "codex CLI not found on PATH" >&2
  exit 127
fi

mkdir -p "$cwd/.pstack/workers"

if [[ -z "$output" ]]; then
  stamp="$(date +%Y%m%d-%H%M%S)"
  output="$cwd/.pstack/workers/${stamp}-thermo-review.md"
fi

mkdir -p "$(dirname "$output")"

if [[ -z "$log_file" ]]; then
  log_file="${output%.*}.jsonl"
fi

if [[ -z "$pid_file" ]]; then
  pid_file="${output%.*}.pid"
fi

mkdir -p "$(dirname "$log_file")" "$(dirname "$pid_file")"

if [[ "$target" == "uncommitted" ]]; then
  target_text="Review the repository's uncommitted changes."
else
  target_text="Review the current branch against ${base}."
fi

prompt="$(cat <<EOF
Run a thermo-nuclear code quality review.

Target:
${target_text}

Review standard:
- Be strict about structural maintainability.
- Look for code-judo simplifications that preserve behavior while deleting branches, helpers, layers, modes, or concepts.
- Treat files crossing 1000 lines, ad-hoc condition growth, thin wrappers, cast-heavy boundaries, canonical-helper duplication, wrong-layer logic, sequential orchestration, and non-atomic updates as serious smells.
- Do not spend review budget on cosmetic nits while structural issues exist.

Extra user scope:
${extra_prompt:-None.}

Return:
- blocking findings first,
- file and line for each finding,
- why it harms maintainability,
- the simpler structure to prefer,
- residual risks or "no blocking findings" when appropriate.
EOF
)"

cmd=(
  codex exec
  --cd "$cwd"
  --sandbox read-only
  --model "$model"
  -c "model_reasoning_effort=\"$reasoning\""
  -c "service_tier=\"$service_tier\""
  --output-last-message "$output"
)

if [[ "$json" -eq 1 ]]; then
  cmd+=(--json)
fi

if [[ "$target" == "uncommitted" ]]; then
  prompt="${prompt}

Suggested command to inspect target:
git diff --stat && git diff"
else
  prompt="${prompt}

Suggested command to inspect target:
git diff --stat ${base}...HEAD && git diff ${base}...HEAD"
fi

printf 'Starting thermo-nuclear Codex reviewer with model=%s reasoning=%s service_tier=%s\n' "$model" "$reasoning" "$service_tier" >&2
printf 'Output: %s\n' "$output" >&2

if [[ "$background" -eq 1 ]]; then
  printf 'Log: %s\n' "$log_file" >&2
  printf 'PID file: %s\n' "$pid_file" >&2
  nohup "${cmd[@]}" "$prompt" >"$log_file" 2>&1 &
  child_pid=$!
  printf '%s\n' "$child_pid" >"$pid_file"
  printf 'Codex reviewer started in background with pid %s\n' "$child_pid" >&2
  exit 0
fi

"${cmd[@]}" "$prompt"
printf '\nCodex reviewer final message: %s\n' "$output" >&2
