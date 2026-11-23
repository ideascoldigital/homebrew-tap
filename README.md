# Homebrew tap — IdeasCol Digital

Homebrew distribution for IdeasCol Digital software: desktop apps ship as casks,
command line tools as formulae.

```sh
brew tap ideascoldigital/tap
brew trust ideascoldigital/tap
```

`brew trust` is not optional: Homebrew 7 refuses to load anything from a
third-party tap until the tap is trusted once per machine.

## Available

| Install | What it is |
| --- | --- |
| `brew install --cask ideascoldigital/tap/nexus` | [Nexus](https://github.com/ideascoldigital/nexus) — local-first AI dev orchestrator |

Keep `--cask` and the full name: `homebrew/core` has an unrelated formula also
called `nexus` (Sonatype Repository Manager), and `brew install nexus` installs
that one.

Upgrades follow the usual path once a new version lands here:

```sh
brew upgrade --cask nexus
```

### Nexus notes

- Apple Silicon only. `release-native.yml` builds macOS on the arm64 runner
  alone, because the sidecar embeds the build host's own `node` binary, so no
  x86_64 dmg exists to point Intel Macs at.
- The app is ad-hoc signed, not notarized. The cask strips the quarantine flag
  after install, otherwise macOS claims the app is damaged on first launch. Sign
  and notarize the bundle in the release workflow and that step can go away.
- `brew uninstall --cask nexus` leaves `~/.nexux` alone (database, logs,
  workspaces). `brew uninstall --zap --cask nexus` deletes it too.

## Publishing a new version

From the Actions tab, run the **bump** workflow with the app name and the new
version. It rewrites the version, recomputes the sha256 from the published
artifact, re-audits and commits to `main`.

Publish the GitHub release first. `release-native.yml` in nexus attaches its
bundles to a *draft* release, and a draft is invisible to both the anonymous
download and `brew livecheck`, so bumping before publishing fails instead of
committing a broken checksum. A bump to anything other than the newest
published release fails the same way, on purpose.

To have an app repository do it on its own, give it a workflow that fires when a
release is **published** — not when the build finishes, since a draft release is
invisible to both the anonymous download and livecheck:

```yaml
on:
  release:
    types: [published]

jobs:
  bump:
    if: ${{ !github.event.release.prerelease }}
    runs-on: ubuntu-latest
    steps:
      - env:
          TAP_TOKEN: ${{ secrets.HOMEBREW_TAP_TOKEN }}
          TAG: ${{ github.event.release.tag_name }}
        run: |
          curl -fsSL -X POST \
            -H "Accept: application/vnd.github+json" \
            -H "Authorization: Bearer $TAP_TOKEN" \
            https://api.github.com/repos/ideascoldigital/homebrew-tap/dispatches \
            -d "$(jq -nc --arg v "${TAG#v}" \
                  '{event_type:"bump",client_payload:{app:"<token>",version:$v}}')"
```

`nexus` has this as `.github/workflows/bump-homebrew.yml`. `HOMEBREW_TAP_TOKEN`
is a fine-grained token scoped to this repository alone with `Contents: Read and
write` — the app repository's own `GITHUB_TOKEN` cannot reach across
repositories. It is a user token, so it dies with the user's access and expires
on its own; the bump workflow can always be run by hand from the Actions tab in
the meantime.

## Adding an app

A desktop app goes in `Casks/<token>.rb`, a CLI in `Formula/<Name>.rb`. Both are
plain Homebrew files; the ones already here are the shortest reference.

Worth getting right in a cask:

- `depends_on arch: :arm64` whenever only one architecture is built, so Intel
  users get a clear refusal instead of a broken install.
- `livecheck` with `strategy :github_latest`, so `brew livecheck` can report
  what is outdated.
- `zap trash:` for anything the app writes outside its bundle.
- An unsigned bundle needs the quarantine flag cleared in `postflight_steps`.

A formula that ships a prebuilt binary per architecture needs an `on_arm` /
`on_intel` block with its own `url` and `sha256`; `brew bump-formula-pr` only
rewrites the primary url, so those are bumped by hand.

Open a pull request: `tests` runs `brew style` and `brew audit --online` against
the branch as if it were already merged.
