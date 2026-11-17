# Security

## Reporting

Report a vulnerability through [private vulnerability reporting](https://github.com/AshwinSathian/loupe-action/security/advisories/new). Please don't open a public issue for it.

## What this action does with your job

- It installs one exact version of [`loupe-review`](https://www.npmjs.com/package/loupe-review) from npm with `--ignore-scripts`, then the browser build that version's Playwright expects. On Linux runners that includes `--with-deps`, which installs system libraries with `apt-get` (it needs `sudo`, as hosted runners have). Self-hosted and container jobs without `sudo` need the browser's dependencies installed beforehand.
- It opens the URLs you give it in a real browser and runs loupe's scripts in the page. The browser runs whatever the page runs: point it only at pages you control, and keep secrets out of the job.
- Inputs reach the scripts as environment variables, never spliced into shell text. `urls` must be `http` or `https`, and every option goes to loupe as one `--name=value` argument, so a value can't be read as another option. `version`, `browser` and `timeout` are validated before anything runs.
- Its network traffic is the npm registry, Playwright's browser download, and (on Linux) your runner's package mirrors, plus the pages you point it at.
- It doesn't modify your repository or workspace. It writes the browser to its usual cache, system packages on Linux, and its reports under `RUNNER_TEMP`.
- The action itself needs no token permissions (`permissions: {}` is enough). Your workflow still needs `contents: read` to check out the code, and the files for `baseline` and `storage-state` must be in the workspace.

## Supply chain

The action uses no other actions at run time (no `uses:` steps). What it installs is one exact `loupe-review` version and that version's dependencies, which an `npm-shrinkwrap.json` inside the package locks, so the tree is the one the maintainer tested (2.1.0 was the first release to ship it). The action's own test workflow pins every action by commit SHA. `loupe-review` is published from GitHub Actions with npm trusted publishing, so each release carries signed provenance, and no npm token exists in its repository.
