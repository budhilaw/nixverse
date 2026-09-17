<p align="center">
  <img src="nixverse.png" alt="nixverse" width="180">
</p>

<h1 align="center">nixverse</h1>

<p align="center">One flake for all of my machines.</p>

| Host | Hardware | OS | Output |
|------|----------|----|--------|
| `macbook-air` | MacBook Air M4, personal (hostname `budhilaw`) | macOS + nix-darwin + Determinate Nix | `darwinConfigurations.macbook-air` |
| `macbook-pro` | MacBook Pro M2, office | macOS + nix-darwin + Determinate Nix | `darwinConfigurations.macbook-pro` |
| `homelab-lenovo` | Lenovo M920Q, Malang | NixOS (services as containers) | `nixosConfigurations.homelab-lenovo` |

All three share one home-manager profile (`budhilaw`): fish + starship + atuin,
git with directory-based identities, SSH host aliases, sops-managed keys.

## Layout

```
flake.nix                       inputs
nix/default.nix                 flake-parts + ez-configs wiring, shared nixpkgs config
nix/overlays.nix                pkgs.stable (nixpkgs release branch)
nix/dev-shells.nix              nix develop ~/.config/nixverse#<name>
nix/configurations/
  darwin/macbook-air.nix        personal Mac: identity, secrets it carries, iTerm2 profile
  darwin/macbook-pro.nix        office Mac: work key only
  nixos/homelab-lenovo/         server: hardware, disko, services, containers
  home/budhilaw.nix             shared home profile (ssh aliases, public keys)
nix/modules/
  darwin/                       auto-imported into every darwin host
  nixos/                        auto-imported into every nixos host
  home/                         auto-imported into the home profile
secrets/                        sops-encrypted (safe to commit); *.example = shape
.sops.yaml                      who can decrypt what
```

ez-configs turns file names into outputs, imports `modules/<kind>/*` into every
host of that kind, and attaches the home profile to each host listed in
`nix/default.nix`. Anything that should only apply to one machine lives in
that machine's file under `configurations/`, including per-host home-manager
overrides via `home-manager.users.budhilaw`.

## Day to day

```sh
drs                      # Mac: sudo darwin-rebuild switch --flake ~/.config/nixverse#<this host>
nrs                      # homelab: sudo nixos-rebuild switch --flake ~/.config/nixverse#homelab-lenovo
flakeup                  # nix flake update (flakeup nixpkgs for one input)
nd go                    # enter a dev shell (see nix/dev-shells.nix for names)
nix flake check          # eval every host + run nixfmt/deadnix
```

Deploy the homelab from the Mac (builds on the server, which is x86_64):

```sh
nixos-rebuild switch --flake ~/.config/nixverse#homelab-lenovo \
  --target-host homelab --build-host homelab --ask-sudo-password
```

## Secrets

Encrypted with [sops-nix](https://github.com/Mic92/sops-nix) + age.

- **Macs**: personal age key from 1Password at `~/.config/sops/age/keys.txt`.
  It decrypts SSH/GPG private keys into `~/.ssh` and the GPG keyring on rebuild.
  One key per trust domain: personal, work (`amartha`), business. The Air
  carries all three; the office Mac carries only the work key.
- **Homelab**: decrypts with its own SSH host key (`ssh-to-age`), so the
  personal key never lands on the server. Its file is
  `secrets/homelab-lenovo.yaml`.

```sh
export SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt
sops secrets/homelab-lenovo.yaml       # edit in $EDITOR, re-encrypts on save
sops secrets/budhilaw-ssh.yaml
```

Adding a machine that needs secrets: derive its recipient
(`ssh-keyscan -t ed25519 <host> | ssh-to-age`), add it to `.sops.yaml`, then
`sops updatekeys` the files it should read.

## New Mac

```sh
# 1. Determinate Nix: https://dtr.mn/determinate-nix
# 2. age key from 1Password
mkdir -p ~/.config/sops/age && $EDITOR ~/.config/sops/age/keys.txt && chmod 600 ~/.config/sops/age/keys.txt
# 3. first switch (later ones are just `drs`); pick macbook-air or macbook-pro
git clone git@github.com:budhilaw/nixverse.git ~/.config/nixverse
cd ~/.config/nixverse
sudo nix run nix-darwin/nix-darwin/master#darwin-rebuild -- switch --flake .#macbook-pro
# 4. tailnet (Homebrew formula, not the App Store app, so it can use Headscale)
sudo tailscaled install-system-daemon
sudo tailscale up --login-server https://headscale.budhilaw.com
```

## Homelab: first install

The M920Q currently runs Ubuntu 24.04 with three docker-compose stacks under
`/opt`. The NixOS config reproduces them as `virtualisation.oci-containers`
(same images, same volume paths, same ports) and moves the host-level pieces
(tailscale, cloudflared, cloudnan-agent, the SOCKS proxy) to systemd units.
`nixos-anywhere` wipes the NVMe, so state has to be carried across by hand.

1. **Fill the secrets** in `secrets/homelab-lenovo.yaml` from `/opt/*/.env`
   and `/opt/homelab/docker-compose.yml` (gluetun key, vaultwarden admin
   token, tunnel token, DB passwords).
2. **Back up state to the USB disk** (kept intact; disko only touches the NVMe):
   ```sh
   ssh homelab
   sudo rsync -aHAX /opt/ /mnt/hdd-ext/migrate/opt/
   sudo rsync -aHAX /var/lib/tailscale/ /mnt/hdd-ext/migrate/tailscale/
   sudo cp -a /etc/cloudnan /usr/local/bin/cloudnan-agent /mnt/hdd-ext/migrate/
   sudo cp -a /etc/ssh/ssh_host_ed25519_key* /mnt/hdd-ext/migrate/
   ```
3. **Install** from the Mac. `--extra-files` seeds the new root with the old
   SSH host key (keeps the sops recipient and known_hosts valid) and the
   tailscale state (keeps the node identity `100.64.0.1`, no re-enrol):
   ```sh
   mkdir -p /tmp/extra/etc/ssh /tmp/extra/var/lib/tailscale
   scp homelab:/mnt/hdd-ext/migrate/ssh_host_ed25519_key* /tmp/extra/etc/ssh/
   scp -r homelab:/mnt/hdd-ext/migrate/tailscale/ /tmp/extra/var/lib/
   chmod 600 /tmp/extra/etc/ssh/ssh_host_ed25519_key
   nix run nixpkgs#nixos-anywhere -- --flake .#homelab-lenovo \
     --build-on remote --extra-files /tmp/extra --target-host budhilaw@192.168.18.75
   ```
   nixos-anywhere needs root on the target: enable passwordless sudo for the
   install window, or SSH as root. Run it on the LAN, not through the tunnel.
4. **Restore state** after first boot:
   ```sh
   ssh homelab
   sudo rsync -aHAX /mnt/hdd-ext/migrate/opt/ /opt/
   sudo mkdir -p /var/lib/cloudnan /var/lib/socks-proxy
   sudo cp /mnt/hdd-ext/migrate/cloudnan-agent /var/lib/cloudnan/
   sudo cp -r /mnt/hdd-ext/migrate/cloudnan /etc/cloudnan
   sudo cp /opt/homelab/socks-proxy/id_ed25519 /opt/homelab/socks-proxy/known_hosts /var/lib/socks-proxy/
   sudo systemctl restart cloudnan-agent socks-proxy
   ```
5. `nixos-rebuild switch ... --target-host homelab` from then on.

Reserve `192.168.18.75` for the box's MAC on the router; the config uses DHCP.

## Dev shells

`nix/dev-shells.nix`: `go`, `goService`, `goAgent`, `carikelas`, `budhilaw`
(Go); `nodejs`, `nodejs20/22/24`, `webApp`, `carikelasWeb`, `budhilawWeb`
(Node, from the stable branch for cache hits); `python`, `python312`,
`python313`; `rust`; `java`; `php`. `default` is for hacking on this repo and
installs the nixfmt/deadnix pre-commit hooks.

## Acknowledgements

Started from [r17x/universe](https://github.com/r17x/universe). Built on
[nix-darwin](https://github.com/nix-darwin/nix-darwin),
[home-manager](https://github.com/nix-community/home-manager),
[flake-parts](https://github.com/hercules-ci/flake-parts),
[ez-configs](https://github.com/ehllie/ez-configs),
[sops-nix](https://github.com/Mic92/sops-nix),
[disko](https://github.com/nix-community/disko).
