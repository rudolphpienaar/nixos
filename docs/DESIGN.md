# Design

## Purpose

This repository records the structure and rationale of the current NixOS workstation configuration. Its purpose is not merely to list files, but to preserve the design intent behind the machine as it evolved from a first-contact NixOS installation into a flake-based, Home Manager-driven development environment.

The system is designed around a clear separation of concerns. The operating system should describe the host. Home Manager should describe the user environment. The flake should describe and pin the upstream inputs from which both are evaluated.

## Configuration Topology

The present system is organized as a flake rooted at `/etc/nixos`.

The principal files are:

- `/etc/nixos/flake.nix`
- `/etc/nixos/flake.lock`
- `/etc/nixos/configuration.nix`
- `/etc/nixos/hardware-configuration.nix`
- `/etc/nixos/home.nix`
- `/etc/nixos/home/`

The intended responsibility of each is distinct.

`flake.nix` defines the pinned upstream inputs and exposes the named system output `nixosConfigurations.callisto`. `flake.lock` records the exact revisions currently in use. `configuration.nix` describes host-level behavior such as boot configuration, networking, display services, audio, fonts, users, and Home Manager integration. `hardware-configuration.nix` remains the machine-specific hardware module generated for this host. `home.nix` is deliberately thin and imports the Home Manager module tree found under `/etc/nixos/home/`.

This arrangement favors composability over centralization. The top level establishes identity and evaluation context. The module tree carries the user environment in coherent, bounded files.

## System Layer And User Layer

The machine is intentionally divided into two logical layers.

The system layer consists of NixOS modules that define host identity and shared operating-system behavior. These include the bootloader, kernel package selection, GNOME, PipeWire, locale, hostname, networking, and user account definition. These settings belong to the host because they change the machine itself rather than the interactive environment of one person.

The user layer consists of Home Manager modules that define the interactive engineering environment. These include shell aliases, prompt initialization, tmux behavior, editor linkage, command-line packages, `lsd`, `atuin`, `broot`, splash behavior, and similar tooling. These settings belong to the user because they express workflow rather than host identity.

The purpose of this separation is not aesthetic. It reduces reasoning cost. When a change is proposed, the first question should be whether it affects the machine or the user. The file placement should then follow directly from the answer.

## Flake Model

The flake model was adopted to make inputs explicit and evaluation reproducible. In the earlier non-flake configuration, Home Manager was imported through an inline `fetchTarball`, and the system relied more heavily on ambient evaluation context. This was valid but less explicit.

Under the current design, the flake provides:

- pinned `nixpkgs`
- pinned `home-manager`
- a named output for the host: `callisto`

The normal rebuild path is therefore:

```bash
sudo nixos-rebuild switch --flake /etc/nixos#callisto
```

This is the canonical activation path. Any helper scripts should target it rather than the legacy non-flake rebuild form.

## Home Manager Module Tree

The Home Manager configuration is intentionally modular. The current module tree exists to keep the top-level file legible and to keep large operational payloads out of inline Nix strings wherever possible.

The design intent of the current modules is as follows:

- `/etc/nixos/home/packages.nix`
  Declares user-facing packages installed through Home Manager.

- `/etc/nixos/home/session.nix`
  Declares session paths and environment variables.

- `/etc/nixos/home/zsh.nix`
  Declares interactive shell behavior, aliases, prompt sourcing, and shell helper functions.

- `/etc/nixos/home/tmux.nix`
  Declares tmux behavior and installs the tmux powerline theme.

- `/etc/nixos/home/atuin.nix`
  Declares shell history synchronization behavior.

- `/etc/nixos/home/broot.nix`
  Declares file-navigation integration.

- `/etc/nixos/home/lsd.nix`
  Declares modern `ls` replacement behavior and shell integration.

- `/etc/nixos/home/avim.nix`
  Declares AstroNvim linkage through `NVIM_APPNAME` and an out-of-store config symlink.

- `/etc/nixos/home/splash.nix`
  Installs the login splash script.

- `/etc/nixos/home/files/`
  Holds real payload files that should exist as files rather than inline strings.

This design favors shallow modules with single responsibilities. It is acceptable for new modules to be added when a concern grows large enough to deserve its own boundary.

## Operational Payload Files

Two payloads are intentionally stored as real files rather than embedded Nix text blocks:

- `/etc/nixos/home/files/splash.zsh`
- `/etc/nixos/home/files/tmux-powerline-callisto.sh`

The reason is practical. Both are operational scripts with their own internal structure. They are easier to read, edit, diff, and debug as files than as quoted multiline strings inside a Nix module.

This does not make them less declarative. Home Manager still installs them through `xdg.configFile`, and their presence remains part of the declared system state. The change is one of representation, not of authority.

## AstroNvim Strategy

The current Neovim strategy is intentionally hybrid.

The AstroNvim-derived configuration remains in a separate repository and is linked into `~/.config/avim` using an out-of-store symlink. This avoids a premature translation of a large, evolving editor configuration into Nix while still allowing the machine to provide its runtime dependencies declaratively.

This means Nix owns the environment around the editor, while the editor configuration repository remains the direct source of truth for AstroNvim behavior.

The design rationale is to preserve velocity. Editor logic changes frequently and belongs in its own repository. Runtime tooling such as `ripgrep`, `fd`, clipboard tools, formatters, and language servers belong in Home Manager.

## Splash Philosophy

The splash is intentionally treated as a dashboard, not as ornamental startup noise. It preserves information that has historically mattered at terminal entry:

- machine identity
- session listing
- local process pressure
- local and remote weather context
- calendar position
- current time
- CPU summary
- broader system summary
- a trailing quote or fortune

The splash therefore sits at the boundary between tradition and utility. It preserves continuity with a long-lived shell environment while being implemented in a form appropriate to the current machine and configuration model.

Its implementation should remain visually disciplined but operationally secondary. If the splash ever begins to dominate `home.nix` again, it should be moved further outward into standalone files rather than pulling the configuration back toward a monolith.

## Helper Workflow

The local helper workflow exists to reduce typing, not to create a second package-management model.

Examples include:

- `ns` for package search
- `nsi` for adding a package to `home.packages` and rebuilding declaratively

These helpers are acceptable only insofar as they remain thin wrappers over the canonical configuration files and flake rebuild path. They should never become a hidden state system of their own.

## Design Rule

The governing rule of this configuration is simple: keep declaration, provenance, and operational payloads aligned.

Declaration should live in Nix modules. Provenance should live in the flake and its lock file. Operational payloads should live in real files when they are large enough to deserve direct editing. Whenever one of these categories starts absorbing the concerns of another, the configuration should be split again before drift hardens into debt.
