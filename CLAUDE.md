# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

**Nixverse** is a comprehensive, modular Nix configuration system for cross-platform development environments. It supports Darwin (macOS), NixOS, and NixOS WSL configurations using the ez-configs framework for streamlined module management.

## Common Development Commands

### System Rebuild Commands
- **macOS**: `darwin-rebuild switch --flake ~/.config/nixverse` or use the alias `drs`
- **NixOS/WSL**: `sudo nixos-rebuild switch --flake .#$HOSTNAME`
- **Home Manager**: `home-manager switch --flake ~/.config/nixverse`

### Development Shells
Enter pre-configured development environments:
```bash
# Node.js environments (versions 14, 18, 20, 22)
nix develop ~/.config/nixverse#nodejs22
nix develop ~/.config/nixverse#nodejs20

# Language-specific shells
nix develop ~/.config/nixverse#go        # Go with full toolchain
nix develop ~/.config/nixverse#rust      # Rust development
nix develop ~/.config/nixverse#python    # Python with venv support
```

### Flake Management
- **Update all inputs**: `flakeup-all` (alias) or `nix flake update ~/.config/nixverse`
- **Update specific input**: `flakeup <input>` (alias) or `nix flake lock ~/.config/nixverse --update-input <input>`
- **Check flake**: `nix flake check ~/.config/nixverse`

### Cleanup Commands
- **Comprehensive cleanup**: `nclean` (alias) - runs garbage collection, store optimization, and verification
- **Quick garbage collection**: `nix-collect-garbage -d`

### Pre-commit Hooks
The repository uses pre-commit hooks with:
- **Formatter**: `nixfmt-rfc-style` (set as default formatter)
- **Enabled hooks**: actionlint, shellcheck, stylua, deadnix, nixfmt-rfc-style, dune-fmt
- **Run hooks**: Hooks run automatically on commit, or manually via the default devShell

## Architecture and Structure

### Core Organization
```
nix/
├── default.nix           # Main configuration orchestrator using ez-configs
├── devShells.nix         # Development environment definitions
├── configurations/       # Platform-specific user configurations
│   ├── darwin/          # macOS configurations
│   ├── home/            # Home-manager configurations  
│   └── nixos/           # NixOS/WSL configurations
├── modules/             # Modular components
│   ├── cross/           # Cross-platform modules (shared settings)
│   ├── darwin/          # macOS-specific modules (homebrew, etc.)
│   ├── flake/           # Flake infrastructure (rebuild scripts, module config)
│   ├── home/            # Home-manager modules (shells, git, gpg, etc.)
│   └── nixos/           # NixOS modules
└── overlays/            # Package overlays and customizations
    ├── mac-pkgs/        # macOS app overlays (Cursor, Brave, etc.)
    └── nodePackages/    # Node.js package definitions via node2nix
```

### Multi-Platform Support Architecture
- **ez-configs integration**: Streamlined configuration management across platforms
- **Modular design**: Cross-platform modules for shared functionality, platform-specific modules for specialized features
- **Three target platforms**: macOS (via nix-darwin + Homebrew), NixOS (native), WSL (with Windows tool integration)

### Key Integrations
- **SOPS-nix**: Secret management system integrated across configurations
- **Fish shell**: Default shell with extensive customization and aliases
- **Home-manager**: User environment configuration across all platforms
- **Multiple nixpkgs branches**: stable, unstable, and master for flexibility

## Shell Aliases and Functions

The system provides numerous aliases (defined in `nix/modules/home/shells.nix:shellAliases`):

### Nix-specific aliases
- `drs` - Darwin rebuild switch (macOS)
- `flakeup-all` - Update all flake inputs  
- `flakeup <input>` - Update specific input
- `nclean` - Comprehensive Nix cleanup pipeline
- `nb` - nix build
- `nr` - nix run
- `nf` - nix flake
- `nd <shell>` - nix develop (function: `nd go` enters Go devShell)

### Git aliases
- `g` - git
- `gl` - git log --graph --oneline --all
- `gfa` - git fetch --all
- `grc` - git rebase --continue
- `gri` - git rebase --interactive

### System utilities
- `grep` - ripgrep (rg)
- `cat` - bat
- `du` - dust
- `c` - zoxide (z)
- `e` - nvim

### Platform-specific functions
- **WSL only**: `cursor <path>` - Launch Cursor IDE from WSL with Windows path conversion

## Development Environment Features

### Language Support
- **Node.js**: Multiple versions (14, 18, 20, 22) with npm, yarn, pnpm
- **Go**: Full toolchain including gopls, golangci-lint, delve, go-migrate, protoc-gen-go
- **Rust**: rustup, cargo, clippy, rustfmt with WebAssembly support
- **Python**: venv support, testing tools (pytest), formatting (black), linting (flake8, mypy)
- **OCaml/ReasonML**: Development environment support

### Development Tools
- **direnv**: Directory-based environment loading (`da` = direnv allow, `dr` = direnv reload)
- **atuin**: Enhanced shell history with Ctrl+R search
- **zoxide**: Smart directory jumping
- **starship**: Modern shell prompt with Git integration

## Package Management

### Custom Overlays
- **macOS applications**: Located in `nix/overlays/mac-pkgs/` - includes Cursor, Brave, MongoDB Compass, etc.
- **Node.js packages**: Generated via node2nix in `nix/overlays/nodePackages/`
- **Package fixes**: Custom overlays for package modifications and fixes

### Homebrew Integration (macOS)
Seamless integration with Homebrew for macOS-specific applications and tools via nix-darwin.

## Special Configurations

### Secret Management
Uses SOPS-nix for managing secrets across all platform configurations.

### WSL Integration
- Windows tool integration (Cursor IDE path conversion)
- Seamless file system access between WSL and Windows
- NixOS-WSL specific modules for Windows interoperability