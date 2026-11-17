#!/usr/bin/env bash
# Runs loupe on the listed URLs. Every input arrives as an environment variable and is passed to loupe as
# one argument in --name=value form, so a value can never be read as another option.
set -uo pipefail

dir="${RUNNER_TEMP:?}/loupe-review"
bin="$dir/node_modules/.bin/loupe"

# Invalid input: report exit code 2 as an output, so a later step can tell this from a missing run.
bad() {
  echo "::error title=Loupe Review::$1"
  echo "exit-code=2" >> "$GITHUB_OUTPUT"
  exit 2
}

[ -x "$bin" ] || bad "loupe is not installed; the install step did not run"

urls=()
while IFS= read -r line; do
  line="${line//$'\r'/}"
  line="${line#"${line%%[![:space:]]*}"}"
  line="${line%"${line##*[![:space:]]}"}"
  [ -z "$line" ] && continue
  if ! [[ "$line" =~ ^https?://[^[:space:]]+$ ]]; then
    bad "each url must start with http:// or https:// and contain no spaces"
  fi
  urls+=("$line")
done <<< "${LOUPE_URLS:-}"
if [ "${#urls[@]}" -eq 0 ]; then
  bad "urls is empty"
fi

timeout_ms="${LOUPE_TIMEOUT:-30000}"
[[ "$timeout_ms" =~ ^[0-9]+$ ]] || bad "timeout must be a number of milliseconds, got '$timeout_ms'"
if [ -n "${LOUPE_BASELINE:-}" ] && [ ! -f "$LOUPE_BASELINE" ]; then
  bad "baseline file not found: $LOUPE_BASELINE (write one with: loupe <url> --baseline <file> --update-baseline)"
fi

# One directory per invocation, so a second run in the same job cannot overwrite or leak into the first.
out="$(mktemp -d "$dir/out.XXXXXX")"
md="$out/loupe.md"
json="$out/loupe.json"

args=("${urls[@]}" "--md=$md" "--json=$json" "--only=${LOUPE_ONLY:-measure,interact,stress}" "--browser=${LOUPE_BROWSER:-chromium}" "--timeout=$timeout_ms")
[ -n "${LOUPE_WIDTHS:-}" ] && args+=("--widths=$LOUPE_WIDTHS")
[ -n "${LOUPE_WAIT_FOR:-}" ] && args+=("--wait-for=$LOUPE_WAIT_FOR")
[ -n "${LOUPE_STORAGE_STATE:-}" ] && args+=("--storage-state=$LOUPE_STORAGE_STATE")
[ -n "${LOUPE_BASELINE:-}" ] && args+=("--baseline=$LOUPE_BASELINE")
[ -n "${LOUPE_FAIL_ON:-}" ] && args+=("--fail-on=$LOUPE_FAIL_ON")

"$bin" "${args[@]}"
code=$?

if [ "${LOUPE_SUMMARY:-true}" = "true" ] && [ -f "$md" ] && [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
  cat "$md" >> "$GITHUB_STEP_SUMMARY"
fi

# Paths are outputs only if loupe wrote the file (it does not when it fails before the report).
{
  [ -f "$md" ] && echo "markdown=$md"
  [ -f "$json" ] && echo "json=$json"
  echo "exit-code=$code"
} >> "$GITHUB_OUTPUT"

if [ "$code" -eq 1 ]; then
  echo "::error title=Loupe Review::findings at the fail-on level. See the job summary."
elif [ "$code" -ne 0 ]; then
  echo "::error title=Loupe Review::loupe exited with code $code (usage, page load or browser error)."
fi
exit "$code"
