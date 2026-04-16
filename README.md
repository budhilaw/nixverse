# Nixverse

A modular Nix configuration system for managing macOS (Darwin), NixOS, and NixOS WSL environments. One flake, one rebuild, and your entire machine is reproducible — packages, secrets, shell, git identities, and all.

## Features

- **Modular Design** — Organized modules for Darwin, NixOS, WSL, and Home Manager
- **Dev Shells** — Pre-configured environments for Node.js, Go, Rust, Python, PHP
- **Secret Management** — SSH and GPG keys encrypted with [sops-nix](https://github.com/Mic92/sops-nix) + age, auto-decrypted on rebuild
- **Multi-Identity Git** — Directory-based git user/email/GPG key switching (e.g. `~/Dev/Personal/` vs `~/Dev/Amartha/`)
- **macOS Automation** — Dock, Finder, Brave, iTerm2 defaults managed declaratively via nix-darwin
- **Homebrew Integration** — GUI apps (casks) and Mac App Store apps managed through Nix
- **Fish Shell** — Starship prompt, Atuin history, Zoxide navigation, 50+ aliases
- **WSL Integration** — Docker Desktop, VS Code Server, tmpfs root

## Project Structure

```
nixverse/
├── flake.nix                # Entry point — inputs, outputs, system configurations
├── flake.lock               # Pinned dependency versions
├── .sops.yaml               # SOPS config (age public key + creation rules)
│
├── secrets/                 # Encrypted secrets (safe to commit)
│   ├── budhilaw-gpg.yaml          # Personal GPG private key (encrypted)
│   ├── amartha-gpg.yaml           # Work GPG private key (encrypted)
│   ├── budhilaw-ssh.yaml          # All SSH private keys (encrypted)
│   └── *.example                  # Templates showing expected format
│
└── nix/
    ├── default.nix          # Flake module wiring
    ├── devShells.nix        # Dev shell definitions
    ├── overlays/            # Package overlays (nixpkgs branches, custom pkgs)
    │
    ├── configurations/      # Per-machine configs
    │   ├── darwin/budhilaw.nix    # macOS system config
    │   ├── home/budhilaw.nix      # Home Manager config (SSH, GPG, git identity)
    │   └── nixos/budhilaw.nix     # NixOS/WSL config
    │
    └── modules/             # Reusable modules
        ├── cross/           # Shared across all platforms (nix settings, nixpkgs, shells)
        ├── darwin/          # macOS: homebrew, system defaults, network/DNS, GPG agent
        ├── home/            # Home Manager: git, gpg, ssh, shells, packages
        ├── nixos/           # NixOS: user creation
        └── flake/           # Flake internals: rebuild scripts, module config
```

## Getting Started

### Prerequisites

- [Nix](https://nixos.org/download/) with flakes enabled
- Git
- macOS (aarch64) or NixOS (x86_64)

### Fresh Machine Setup

#### 1. Clone the repo

```bash
git clone https://github.com/budhilaw/nixverse.git ~/.config/nixverse
cd ~/.config/nixverse
```

#### 2. Set up the age key (for secret decryption)

The age private key is stored in **1Password**. On a new machine, restore it:

```bash
mkdir -p ~/.config/sops/age
# Paste the age private key (AGE-SECRET-KEY-1...) from 1Password into:
#   ~/.config/sops/age/keys.txt
chmod 600 ~/.config/sops/age/keys.txt
```

> **First time ever?** Generate a new key instead:
> ```bash
> nix shell nixpkgs#age -c age-keygen -o ~/.config/sops/age/keys.txt
> ```
> Save the private key to 1Password immediately. Update the public key in `.sops.yaml`.

#### 3. Build and switch

**macOS:**
```bash
nix build .#darwinConfigurations.budhilaw.system -o /tmp/result \
  && sudo /tmp/result/sw/bin/darwin-rebuild switch --flake .#budhilaw
```

**NixOS (including WSL):**
```bash
sudo nixos-rebuild switch --flake .#budhilaw
```

That's it. After rebuild:
- SSH keys are decrypted from sops and placed in `~/.ssh/` (added to macOS Keychain automatically)
- GPG keys are imported into your keyring with ultimate trust
- Git identity switches based on your working directory
- Fish shell, Starship prompt, and all CLI tools are ready
- macOS apps are installed via Homebrew

## Secret Management

Secrets are encrypted with [age](https://github.com/FiloSottile/age) via [sops-nix](https://github.com/Mic92/sops-nix). The encrypted `.yaml` files in `secrets/` are safe to commit — they can only be decrypted with the age private key.

### How it works

1. **`.sops.yaml`** defines which age public key encrypts `secrets/*.yaml` files
2. **`sops-nix`** decrypts secrets at activation time (on `darwin-rebuild switch`)
3. **Home Manager activation scripts** import GPG keys and add SSH keys to Keychain

### Editing secrets

```bash
# Set the age key location (macOS stores it differently than sops expects)
export SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt

# Edit an encrypted file (decrypts → opens editor → re-encrypts on save)
nix run nixpkgs#sops -- secrets/budhilaw-ssh.yaml

# Use a GUI editor (must support --wait so sops knows when you're done)
SOPS_EDITOR="agy --wait" nix run nixpkgs#sops -- secrets/budhilaw-ssh.yaml
```

### Adding a new SSH key

1. Generate the key: `ssh-keygen -t ed25519 -C "you@example.com"`
2. Add the private key to `secrets/budhilaw-ssh.yaml` via sops (indented under a key name)
3. Add the key name to `within.ssh.privateKeys` in `nix/configurations/home/budhilaw.nix`
4. Optionally add the public key to `within.ssh.publicKeys`
5. Add a `programs.ssh.matchBlocks` entry if needed
6. Rebuild

### Adding a new GPG key

1. Generate: `gpg --full-generate-key`
2. Export: `gpg --export-secret-keys --armor 0xYOURKEYID > /tmp/key.asc`
3. Create a new sops file: `nix run nixpkgs#sops -- secrets/yourname-gpg.yaml`
4. Paste the exported key under a descriptive name (e.g. `gpg_yourname_key: |`)
5. Add the entry to `within.gpg.privateKeys` in `nix/configurations/home/budhilaw.nix`:
   ```nix
   within.gpg.privateKeys = {
     gpg_yourname_key = "${inputs.self}/secrets/yourname-gpg.yaml";
   };
   ```
6. Add the key ID to `within.gpg.trustKeyIds`
7. Shred the export: `shred -u /tmp/key.asc`
8. Rebuild

## Git Multi-Identity

Git automatically switches user, email, and GPG signing key based on which directory you're in. Configured in `nix/modules/home/git.nix`:

| Directory | Email | GPG Key |
|-----------|-------|---------|
| `~/Dev/Personal/` | ericsson@budhilaw.com | 0xBD838B746BAA8C5F |
| `~/.config/nixverse/` | ericsson@budhilaw.com | 0xBD838B746BAA8C5F |
| `~/Dev/Amartha/` | ericsson.budhilaw@amartha.com | 0x32B604FD91055131 |

This uses git's `includeIf` directive — it only activates inside a git repo under the matching path. All commits are GPG-signed automatically (`commit.gpgSign = true`).

To add a new identity:
1. Add a new user block in `git.nix`
2. Add a new `home.file.".gitconfig-<name>"` with the user/email/signingKey
3. Add a new `includeIf "gitdir:~/Dev/YourOrg/"` entry pointing to that file

## Development Shells

Pre-configured environments you can enter without installing anything globally:

```bash
# Node.js (multiple versions)
nix develop ~/.config/nixverse#nodejs     # latest
nix develop ~/.config/nixverse#nodejs18
nix develop ~/.config/nixverse#nodejs20
nix develop ~/.config/nixverse#nodejs22
nix develop ~/.config/nixverse#webApp     # Node 24 + yarn + pnpm

# Go
nix develop ~/.config/nixverse#go         # latest
nix develop ~/.config/nixverse#goAgent    # Go 1.23
nix develop ~/.config/nixverse#goService  # Go 1.25 + protobuf/gRPC

# Rust
nix develop ~/.config/nixverse#rust

# Python
nix develop ~/.config/nixverse#python     # pip, virtualenv, black, pytest

# PHP
nix develop ~/.config/nixverse#php        # Composer, Laravel, WordPress tools
```

These are defined in `nix/devShells.nix`. Each shell drops you into a fish shell with the right toolchain on `$PATH`.

## Useful Aliases

Defined in `nix/modules/home/shells.nix`:

### Nix

| Alias | Description |
|-------|-------------|
| `drs` | `darwin-rebuild switch` (rebuild macOS config) |
| `flakeup-all` | Update all flake inputs |
| `flakeup <input>` | Update a specific flake input |
| `nclean` | Full nix store garbage collection |
| `lenv` | List home-manager generations |

### Git

| Alias | Description |
|-------|-------------|
| `pullhead` | Pull current branch from origin |
| `pushhead` | Push current branch to origin |
| `gl` | Pretty one-line git log |
| `gls` | Git log with GPG signature status |
| `gdb` | Delete merged local branches |
| `gdbr` | Delete merged remote branches |

## Customization

### Adding a system package

Edit `nix/modules/home/packages.nix` and add to `home.packages`.

### Adding a macOS app (Homebrew cask)

Edit `nix/modules/darwin/homebrew.nix` and add to the `casks` list.

### Adding a new machine configuration

1. Create a config in the appropriate `nix/configurations/` subdirectory
2. Wire it up in `flake.nix` or `nix/default.nix`
3. Rebuild with `--flake .#your-hostname`

## Updating

```bash
# Update all flake inputs
flakeup-all

# Update a specific input
flakeup nixpkgs

# Rebuild after updating
drs
```

## Author

- **Ericsson Budhilaw** — [GitHub](https://github.com/budhilaw)

## Acknowledgements

- [Universe by r17x](https://github.com/r17x/universe)
- [NixOS](https://nixos.org/) / [nix-darwin](https://github.com/LnL7/nix-darwin) / [home-manager](https://github.com/nix-community/home-manager) / [flake-parts](https://github.com/hercules-ci/flake-parts) / [sops-nix](https://github.com/Mic92/sops-nix)

## License

MIT
