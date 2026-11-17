# Loupe Review

[![Test](https://github.com/AshwinSathian/loupe-action/actions/workflows/test.yml/badge.svg)](https://github.com/AshwinSathian/loupe-action/actions/workflows/test.yml) [![License: MIT](https://img.shields.io/github/license/AshwinSathian/loupe-action)](LICENSE)

A GitHub Action that opens your pages in a real browser and checks what automated scanners usually skip: a keyboard walk with real Tab presses (names, visible focus, traps, focus hidden under a fixed bar), contrast after compositing every translucent layer, target sizes, and stress modes (320 px reflow, WCAG text spacing, 200% text, longer translated text, right-to-left). No model and no API key. It runs [`loupe-review`](https://www.npmjs.com/package/loupe-review), the measuring half of [loupe](https://github.com/AshwinSathian/loupe).

```yaml
- uses: AshwinSathian/loupe-action@v1
  with:
    urls: |
      http://localhost:3000/
      http://localhost:3000/settings
```

The report lands in the job summary. Only measured problems that no WCAG exception covers fail the step: text contrast, targets under 24 px with no spacing exception, a focusable control with no accessible name, a keyboard trap outside a dialog, and focus hidden entirely under fixed content. Heuristics, such as a missing focus style or text that clips under stress, are warnings.

It is a CI gate, not an audit. Automated checks find part of what a manual accessibility review finds, so a clean run says these checks passed, not that the product is accessible. [How loupe compares with axe, Lighthouse and others](https://loupe.ashwinsathian.com/compare).

## Usage

```yaml
name: loupe
on: pull_request
permissions:
  contents: read
jobs:
  loupe:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7
      - uses: actions/setup-node@v7
        with: { node-version: 22 }
      - run: npm ci && npm run build && (npm run start &) && npx wait-on http://localhost:3000
      - uses: AshwinSathian/loupe-action@v1
        with:
          urls: |
            http://localhost:3000/
            http://localhost:3000/settings
          baseline: loupe-baseline.json
```

### Fail only on new findings

Write a baseline once, on the same runner image the check uses, and commit it:

```bash
npx -y loupe-review@2 http://localhost:3000/ http://localhost:3000/settings --baseline loupe-baseline.json --update-baseline
```

With `baseline` set, `fail-on` defaults to `new`. Fonts differ between machines, and with them text widths and target sizes, so a baseline written on a laptop can disagree with one written on `ubuntu-latest`.

## Inputs

| Input | Default | |
|---|---|---|
| `urls` | required | Pages to check, one per line. `http` and `https` only. |
| `version` | `2.1.0` | `loupe-review` version to install. Exact versions only. |
| `only` | `measure,interact,stress` | Which checks to run. |
| `browser` | `chromium` | `chromium`, `webkit` or `firefox`. WebKit is walked with Option-Tab, as Safari skips links on Tab. |
| `widths` | loupe's defaults | Viewport widths in pixels, comma separated. |
| `wait-for` | none | CSS selector to wait for after each page loads. |
| `timeout` | `30000` | Page load timeout in milliseconds. |
| `storage-state` | none | Path to a Playwright storage-state file, for pages behind a sign-in. Treat it as a secret. |
| `baseline` | none | Baseline file written by `loupe --update-baseline`. |
| `fail-on` | `new` with a baseline, else `any` | `new`, `any` or `none`. |
| `summary` | `true` | Write the report to the job summary. |

## Outputs

| Output | |
|---|---|
| `markdown` | Path to the markdown report. Each run writes its own, so several runs in one job don't overwrite each other. Empty if loupe failed before writing it. |
| `json` | Path to the JSON report, with every finding. |
| `exit-code` | `0` passed, `1` findings at the `fail-on` level, `2` invalid input, page-load or browser error. Empty if the action failed before loupe ran, for example on a bad `version`. |

## Baselines from CI

To write the baseline on the same runner image the check uses, add a manual workflow and commit its artifact:

```yaml
name: loupe baseline
on: workflow_dispatch
permissions:
  contents: read
jobs:
  baseline:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7
      - run: npm ci && npm run build && (npm run start &) && npx wait-on http://localhost:3000
      - run: npx -y loupe-review@2 http://localhost:3000/ --baseline loupe-baseline.json --update-baseline
      - uses: actions/upload-artifact@v5
        with: { name: loupe-baseline, path: loupe-baseline.json }
```

## Runners

Tested on `ubuntu-latest` and `macos-latest` (see the [test workflow](.github/workflows/test.yml)), including WebKit on Linux. Node 20 or later must be on the runner; GitHub's hosted runners have it. Windows runners are untested. On Linux the action installs the browser's system libraries with `sudo apt-get`, so self-hosted and container jobs without `sudo` need them installed first.

## Security

The action installs one exact version of `loupe-review` with `--ignore-scripts`, passes every input to the scripts as an environment variable, validates `version`, `browser` and `timeout`, and rejects anything but `http` and `https` URLs. It needs no token permissions of its own. The browser runs whatever the page runs, so point it only at pages you control, keep secrets out of the job, and don't use it with `pull_request_target` on code from forks. Details in [SECURITY.md](SECURITY.md).

`loupe-review` itself is published from GitHub Actions with npm trusted publishing: releases carry signed provenance and no npm token is stored in its repository.

## Versions

`@v1` follows compatible releases. Pin a full tag (`@v1.0.0`) or a commit SHA if you want to review every change. A release's default `version` is the `loupe-review` it was tested with; a new release bumps it.

MIT licensed. loupe is independent and not affiliated with Apple Inc.
