# Releasing

1. Publish the `loupe-review` version you want as the default (its GitHub release runs the npm publish).
2. Set `inputs.version.default` in `action.yml` and the default in the README table to it. Dependabot cannot bump this.
3. Add a CHANGELOG entry, merge, then `gh release create vX.Y.Z`.
4. `release.yml` moves the floating `vX` tag. For the first release of a Marketplace listing, open the release and tick "Publish this Action to the GitHub Marketplace" (needs the Marketplace Developer Agreement and 2FA).
