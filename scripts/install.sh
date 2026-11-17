#!/usr/bin/env bash
# Installs loupe-review (exact version, no install scripts) and the browser build its Playwright expects.
set -euo pipefail

# Inputs are echoed only after control characters are replaced, so a value cannot add a workflow command.
clean() { printf '%s' "${1//[$'\r\n']/ }"; }

version="${LOUPE_VERSION:-}"
browser="${LOUPE_BROWSER:-chromium}"

if ! [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "::error title=Loupe Review::version must be an exact version such as 2.1.1, got '$(clean "$version")'"
  exit 2
fi
case "$browser" in chromium | webkit | firefox) ;; *)
  echo "::error title=Loupe Review::browser must be chromium, webkit or firefox, got '$(clean "$browser")'"
  exit 2
  ;; esac

node_major="$(node -p 'process.versions.node.split(".")[0]')"
if [ "$node_major" -lt 20 ]; then
  echo "::error title=Loupe Review::Node 20 or later is required, found $(node -v). Add actions/setup-node before this step."
  exit 2
fi

dir="${RUNNER_TEMP:?}/loupe-review"
marker="$dir/.installed-$version-$browser"
installed="$(node -p "try{require('$dir/node_modules/loupe-review/package.json').version}catch(e){''}" 2>/dev/null || true)"
# Skip only when this exact version and browser were installed and the package on disk is still that version.
if [ -f "$marker" ] && [ "$installed" = "$version" ]; then
  echo "loupe-review $version with $browser is already installed in this job"
  exit 0
fi
mkdir -p "$dir"
npm install --prefix "$dir" --no-audit --no-fund --ignore-scripts --no-save "loupe-review@$version"

deps=()
if [ "${RUNNER_OS:-}" = "Linux" ]; then deps=(--with-deps); fi
# The Playwright that loupe-review uses: with its npm-shrinkwrap.json it is nested inside the package, not
# hoisted to node_modules/.bin, so find it from the package's own location.
pw_dir="$(cd "$dir/node_modules/loupe-review" && node -p "require('path').dirname(require.resolve('playwright/package.json'))")"
node "$pw_dir/cli.js" install ${deps[@]+"${deps[@]}"} "$browser"

touch "$marker"
echo "loupe-review $("$dir/node_modules/.bin/loupe" --version) installed in $dir"
