# Runbook: try opencode 2 on this machine

Gated procedure for moving one `tui-ide` machine from the pinned opencode 1.x
line ([ADR-0025](../adr/0025-pin-opencode-to-the-1.x-line.md)) to 2.x. The gate
is the corporate LLM gateway (`opencode-go`, a catalog provider): 2.0.22 failed
it with `Unsupported package`; newer 2.x lines normalize v1 catalog configs, so
this must be re-tested per machine, per network.

Rules: Phase 1 touches nothing managed. Do not run `install.sh`, edit the repo,
or change Homebrew until Phase 1 passes AND `origin/main` carries the switch.
If anything in Phase 1 fails: clean up, leave the machine on 1.x, report the
exact output. Do not proceed, and do not "fix" config to make the probe pass.

## Phase 1 - probe (isolated binary, shared config)

1. Record state: `opencode --version` (expect 1.x), note the files under
   `~/.config/opencode/`.
2. Install v2 into a throwaway prefix (never `npm -g` or the curl installer:
   both replace the brew-managed v1 binary):

   ```bash
   mkdir -p ~/.local/opt/opencode-v2-probe
   npm install --prefix ~/.local/opt/opencode-v2-probe @opencode/cli@latest
   ~/.local/opt/opencode-v2-probe/bin/opencode --version   # expect >= 2.x
   ```

3. Gate the gateway with the cheap model lane:

   ```bash
   ~/.local/opt/opencode-v2-probe/bin/opencode run -m opencode-go/space-bunny \
     "reply with exactly: V2-GATEWAY-OK"
   ```

4. Verify the provider actually materialized (a malformed catalog entry is
   silently skipped - the failure mode is a missing provider, not an error):

   ```bash
   ~/.local/opt/opencode-v2-probe/bin/opencode api get /api/config
   ```

   `opencode-go` must appear in `providers` with models.

PASS = step 3 replies `V2-GATEWAY-OK` and step 4 lists the provider.
FAIL = `Unsupported package`, empty or absent providers, auth error, or hang.

Probe side effects are harmless: the first v2 client start may write
`~/.config/opencode/cli.json` and start a background service; the installed v1
ignores both.

On FAIL: `rm -rf ~/.local/opt/opencode-v2-probe`, move any `cli.json` the probe
created into `~/.dotfiles-backup/`, and stop. The pin holds this machine on 1.x
anyway. Report the failure output verbatim; file a compatibility issue upstream
if it looks like catalog or config normalization, per the
[migration guide](https://opencode.ai/v2/docs/migrate-v1).

## Phase 2 - switch the machine

Only after PASS. From the repo checkout, `git pull` and check whether
`origin/main` already carries the v2 switch (the `Brewfile` names
`anomalyco/tap/opencode-v2`).

- If yes:

  ```bash
  brew unpin anomalyco/tap/opencode
  brew uninstall opencode   # conflicts_with makes uninstall-then-install the only path
  ./install.sh              # installs 2.x and seeds cli.json (ADR-0026)
  ```

- If no: this machine is the pilot. Get the owner's explicit go-ahead, make the
  switch change in the repo (see the appendix below), commit, push, then switch
  this machine with the commands above. Later machines take the "yes" path.

## Phase 3 - migrate config, verify

1. `cli.json`: `install.sh` seeds the tracked example, theme `warm-burnout`.
   Move only the values that matter from `~/.config/opencode/tui.jsonc` - v2
   ignores `tui.json(c)` and never auto-migrates the `.jsonc` variant.
   `install.sh` prints the stale-file note. `tui.jsonc` also holds herdr's
   plugin entry: run `herdr integration install opencode`, which writes the v2
   entry into `cli.json` (`"plugins": ["./herdr-opencode"]`) and re-creates
   `tui.jsonc` if it is missing, so leave that file in place - it is inert on v2
   and deleting it only makes herdr report "needs repair" and rewrite it.
2. Plugins: v1 plugin implementations do not run on v2. The herdr TUI session
   plugin and any files under `~/.config/opencode/plugins/` must be v2
   versions (`Plugin.define`, the `plugins` key, a 2.x plugin package) or be
   dropped from `cli.json` until upstream ships them. Do not point v2 at v1
   plugin files.
3. Verify: `opencode --version` reports 2.x; one real session through
   `opencode-go` in a repo you actually work in; the theme renders
   `warm-burnout`; herdr still labels the pane (plain binary,
   [ADR-0031](../adr/0031-retire-the-nono-sandbox.md)).
4. If this machine still has nono or Supacode state from before ADR-0031, run
   `./uninstall-nono-supacode.sh` separately - unrelated to this gate.

## Rollback (any phase)

`brew uninstall opencode-v2` if it landed, then `./install.sh`: the pre-switch
`Brewfile` reinstalls the tap's 1.x and reapplies the pin. If this machine made
the pilot commit, the owner reverts it.

## Repo switch appendix (pilot only)

- `Brewfile`: `brew "anomalyco/tap/opencode-v2"` (the tap tracks the 2.x line
  separately and is fresher than homebrew-core; keep `tap "anomalyco/tap"`);
  rewrite the ADR-0025 comment.
- `install.sh`: trust-loop entry to `anomalyco/tap/opencode-v2`; delete the
  `brew pin` block and its ADR-0025 comment.
- New `docs/adr/0032-track-the-opencode-2.x-line.md` superseding 0025, with an
  index row in `docs/adr/README.md`. Keep ADR-0026 and both client-config
  examples: v1 stays the rollback target, and the version-keyed seeding is what
  makes either line correct.
- `README.md`: the pin paragraph and the provider section.
- `AGENTS.md`: the `opencode --version` verification comment.
- `docs/architecture.md`: the opencode clause.
