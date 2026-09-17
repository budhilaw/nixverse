# nixverse

One flake for three machines: `macbook-air` (personal, hostname `budhilaw`),
`macbook-pro` (office), `homelab-lenovo` (NixOS server). Read `README.md` for
the layout and runbooks before changing anything.

## Rules

- Never add `Co-Authored-By`, "Generated with", or any AI attribution to
  commits, PRs, or files. Plain conventional-commit messages only
  (`feat:`, `fix:`, `docs:`, `chore:`, `refactor:`), subject under 72 chars.
- Never push, force-push, rewrite history, or merge to `main` unless asked in
  that message. Commit only when asked.
- Never decrypt, print, or paste anything from `secrets/*.yaml`. The
  `*.example` files show the shape; edit real values only via `sops`.
- Never run `darwin-rebuild switch` or `nixos-rebuild switch`; they need sudo
  and change the live machine. `darwin-rebuild build` and `nix eval` are fine.
- Do not add flake inputs or Homebrew casks without being asked.

## Verify before you say it works

```sh
nix flake check --option eval-cache false    # all hosts + nixfmt + deadnix
nix eval --raw .#darwinConfigurations.macbook-air.config.system.build.toplevel.drvPath
nix eval --raw .#darwinConfigurations.macbook-pro.config.system.build.toplevel.drvPath
nix eval --raw .#nixosConfigurations.homelab-lenovo.config.system.build.toplevel.drvPath
```

New files must be `git add`ed before the flake can see them. Run `nixfmt` on
every `.nix` file you touch. `nix flake check --no-build` gives false errors
here; use the form above.

## Where things go

- `nix/modules/{darwin,nixos,home}/` is auto-imported into every host of
  that kind. Anything shared goes here.
- `nix/configurations/darwin/<host>.nix` and `nixos/<host>/` hold what is
  true for one machine only: hostname, which secrets it carries, per-host
  home-manager overrides via `home-manager.users.budhilaw`.
- `nix/configurations/home/budhilaw.nix` is the shared home profile.
- Custom options live under `within.*` (`within.gpg`, `within.ssh`,
  `within.dev.enable`, `within.host`). Add new ones there, not at top level.
- `pkgs.stable` is the release branch overlay; use it for toolchains that
  need cache hits (node, k6), unstable for everything else.
- Dev shells are in `nix/dev-shells.nix`; keep the README list in sync.

## Gotchas

- The Air's hostname is `budhilaw`, not `macbook-air`; `within.host` bridges
  that for the `drs` alias. The Pro uses its attribute name as hostname.
- SSH auth goes through Apple's ssh-agent and Keychain, not gpg-agent.
  Do not add a gpg-agent launchd job; it crash-loops.
- The homelab still runs Ubuntu. Its NixOS config evaluates but has never
  booted on the hardware; the cutover runbook is in the README.
- Homelab secrets decrypt with the server's SSH host key. Reinstalling the
  server without carrying that key over breaks every secret.
- macOS PlistBuddy aborts past ~14 `-c` flags in one call; the iTerm2 block
  in `macbook-air.nix` works around it.
- Determinate Nix owns the daemon on macOS; nix settings go through the
  `determinate` module, not `nix.settings`.
