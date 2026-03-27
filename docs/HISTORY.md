# History

## Initial Conditions

This system began as a new NixOS installation approached from the perspective of a long-time Arch Linux user. The immediate objective was not broad system customization, but rapid establishment of a working command-line environment suitable for daily engineering work. The first evening of configuration therefore concentrated on practical essentials: `nodejs`, `zsh`, prompt customization, and command-line AI tooling.

What was established at this stage was a minimally functional workstation. The shell environment became usable for interactive work, and the machine crossed the threshold from a fresh operating system install into a development-capable host.

How this was done was initially conventional and direct. Packages and shell behavior were placed into `/etc/nixos/configuration.nix`, because that file was already present, authoritative, and close at hand during first contact with the system.

Why this approach was acceptable at the outset is straightforward. Early exploration benefits from short feedback loops and low conceptual overhead. At that point, speed of understanding was more valuable than architectural neatness.

## Recognition Of Configuration Debt

After the initial setup, it became clear that the system configuration had started to mix two distinct concerns. Machine-level state such as bootloader selection, desktop environment, networking, audio, and user-account definition was being declared alongside personal shell behavior, aliases, prompt configuration, and developer tool choices.

What was recognized here was not a failure of NixOS, but a structural tension in how the configuration had been evolving. The machine was beginning to accumulate user-environment decisions in the same place as operating-system decisions.

How this became visible was through the attempt to add further user-centric tooling, particularly `tmux`, powerline-style status configuration, and shell refinements. Each additional personal preference increased the density of user-specific state inside `configuration.nix`.

Why this mattered is that NixOS becomes easier to reason about when the boundary between host configuration and user environment is made explicit. Without that separation, the system remains technically functional but becomes harder to maintain, migrate, and audit over time.

## Transition To Home Manager

The next major step was adoption of Home Manager as the mechanism for managing the user environment. This introduced a deliberate split between system-level configuration and user-level configuration.

What changed was the configuration topology. `/etc/nixos/configuration.nix` was reduced toward machine concerns, while a new `/etc/nixos/home.nix` was introduced to carry user packages and user-facing program configuration. The Home Manager module was then wired into the NixOS module system so that user environment activation became part of normal system rebuilds.

How this was done was by importing the Home Manager NixOS module into the system configuration, enabling `home-manager.useGlobalPkgs` and `home-manager.useUserPackages`, and assigning the `rudolph` user to a dedicated `home.nix` module. Existing shell aliases, prompt initialization, `direnv` integration, and package selections were moved into that new file.

Why this migration was the correct move at this stage is that the system was still young enough that reorganization imposed little cost. Moving early avoided the more expensive case in which months of shell, editor, and terminal behavior would later need to be disentangled from the base operating system declaration.

## Integration Of Tmux And Powerline

Once the user environment had a proper home, terminal multiplexing could be added without further blurring the system-user boundary. `tmux` was therefore configured through Home Manager rather than through ad hoc dotfiles or further additions to the global system package set.

What was introduced was a declarative `tmux` configuration with vi-style key handling, mouse support, a `C-a` prefix, large scrollback history, practical split bindings, and a curated set of plugins. The statusline was then connected to `tmux-powerline`, with a dedicated theme file placed under XDG-managed configuration.

How this was implemented required one correction. The initial attempt referred to `tmux-powerline` as a top-level package, but in the active `nixpkgs` set it existed under `pkgs.tmuxPlugins.tmux-powerline`. The configuration was revised to treat it as a tmux plugin rather than a standalone package reference. A custom theme file was then installed via `xdg.configFile`, allowing the status segments to be specified declaratively.

Why this mattered is that terminal behavior is central to interactive engineering work, and tmux is most useful when it is reproducible. A declarative statusline and plugin set avoids silent drift, removes manual plugin bootstrap steps, and establishes a stable baseline for future refinement.

## First-Rebuild Failure Modes

The transition did not succeed on the first attempt. Several failure modes appeared, each of which clarified an aspect of how NixOS and Home Manager interact during early adoption.

What failed first was the system rebuild itself, because `configuration.nix` referenced `/etc/nixos/home.nix` before that file had been installed. This was resolved by creating the referenced file in the expected location.

What failed next was package evaluation, because the `tmux-powerline` attribute name had been specified incorrectly. This was corrected by using the package path that actually existed in the current package set.

What failed after that was Home Manager activation. The service refused to overwrite an existing `~/.zshrc`, and the activation unit exited rather than clobbering a preexisting shell configuration file.

How the final activation issue was resolved was by setting `home-manager.backupFileExtension = "pre-home-manager";` in the NixOS configuration. This instructed Home Manager to preserve existing files by renaming them with a backup suffix before taking ownership of the corresponding managed paths.

Why these failures were useful is that they converted abstract Nix concepts into concrete operational knowledge. The system demonstrated, in a controlled way, how module imports, package attribute names, and file-ownership rules affect declarative configuration in practice.

## Authentication And Administrative Friction

Administrative access also emerged as a practical concern during the migration. Because the configuration files lived in `/etc/nixos`, changes required `sudo`, and noninteractive execution paths made password prompting awkward.

What changed in response was the introduction of passwordless sudo for users in the `wheel` group by setting `security.sudo.wheelNeedsPassword = false;` in the NixOS configuration.

How this was done was declaratively rather than by direct manual editing of `/etc/sudoers`. This preserved the central NixOS principle that privileged system behavior should be expressed in configuration and reproduced through rebuilds.

Why this decision was acceptable is that the machine is being treated as a personal development workstation rather than a shared or hardened host. The change reduced repetitive authentication overhead during rapid iteration, which materially improved the feedback loop while the system was still being shaped.

## Present State

At the conclusion of this phase, the machine had moved beyond exploratory setup and into an explicitly structured configuration model. System concerns and user concerns were no longer conflated, Home Manager had been integrated into the NixOS rebuild process, and the shell environment was under declarative control.

What now exists is an operational baseline suitable for further refinement. The host can be evolved incrementally without returning to purely imperative shell customization.

How future work should proceed is now clearer than it was at the beginning. Machine-wide services should continue to live in `/etc/nixos/configuration.nix`, while shell, terminal, editor, and development tooling should preferentially move through `/etc/nixos/home.nix`.

Why this baseline matters is that it establishes the first durable layer of system memory. The purpose of this document is not merely historical record, but preservation of reasoning: what was changed, how it was achieved, and why those choices were made at the time.

## Powerlevel10k Ownership Boundary

After Home Manager took ownership of the shell entrypoint, prompt customization introduced a subtle but important file-ownership boundary. Running the `powerlevel10k` configuration wizard in a new terminal correctly generated a prompt configuration, but the tool could not modify `~/.zshrc` because that file had become read-only from the user perspective.

What happened was that the wizard produced a new `~/.p10k.zsh` and reported that `~/.zshrc` could not be edited automatically. This was not a malfunction. It was a direct consequence of handing shell initialization over to Home Manager.

How this was resolved was by adjusting the Home Manager `zsh` initialization sequence so that it explicitly sources `~/.p10k.zsh` after loading the `powerlevel10k` theme. This preserved the generated prompt configuration while keeping `~/.zshrc` itself declarative and managed.

Why this distinction matters is that it establishes a stable pattern for future shell customization. Home Manager should own the shell entrypoint, while interactive tools that generate user preferences can write their own secondary configuration files. The prompt system then remains customizable without breaking declarative ownership of the login shell configuration.

## Migration Of Arch-Era Shell Behavior

The next step was to revisit two files carried over conceptually from the older Arch Linux environment: `~/zshrc-pannotia` and `~/.splash`. These files were valuable not because they should be preserved verbatim, but because they encoded accumulated workflow preferences and package expectations.

What was retained from `zshrc-pannotia` included pager behavior, command aliases, `asciidoctor`-based manual viewing helpers, `atuin`, `broot`, `lsd`, and several command-line utilities such as `google-cloud-sdk`, `cpufetch`, `neofetch`, `screenfetch`, `most`, and `fortune`. What was not retained was the old `nvm` bootstrap and direct sourcing of ad hoc launcher files, because NixOS already provided the underlying tools declaratively.

What was discarded from `~/.splash` was the earlier path-construction machinery based on variables such as `self`, `lab`, `java`, and related architecture-specific directory trees. Those assumptions belonged to an older workstation layout and were not meaningful on the new NixOS host.

How the migration was performed was by expressing the enduring shell components directly in Home Manager. Native modules were used where available, notably for `atuin`, `broot`, and `lsd`. A new XDG-managed splash script was then introduced to preserve the login-time banner, uptime, user listing, fortune output, and machine summary while avoiding brittle references to the old directory topology.

Why this selective approach matters is that configuration history should inform the present system without constraining it. The point of migration was not emulation of the old Arch environment, but capture of its useful operational habits in a form that better matches declarative system management.

## Splash Regression And Correction

The first declarative rewrite of the terminal splash preserved the existence of a startup banner but not the full behavior of the original script. In particular, the hardware summary flow was unintentionally weakened and some of the section-level color treatment was flattened.

What regressed was the sequence at the end of the splash. The older script ran `cpufetch` and then, independently, `neofetch` when available. The Nixified version instead used an `if` followed by `elif`, which caused `neofetch` to be skipped whenever `cpufetch` existed. The banner styling was also simplified enough that it no longer matched the visual structure of the original shell experience.

How this was corrected was by restoring the two-stage fetch behavior and reintroducing explicit colorized section boundaries in the XDG-managed splash script. The obsolete path-construction logic from the original file remained excluded, but the visible login-time presentation was brought back into closer alignment with the prior environment.

Why this correction mattered is that migration quality depends on preserving operational semantics, not merely reproducing file names or rough functionality. A shell splash is a small feature, but it exposes whether the new declarative system is actually respecting the habits encoded in the old environment.

## Restoration Of Temporal And Thermal Context

Further recollection of the earlier shell environment established that the splash had historically carried more than a hostname banner and system summary. It also provided temporal context and quick thermal visibility at terminal startup.

What was added back in this stage was a composed dashboard block containing weather, calendar, and large rendered time. The weather pane was restored through `wttr.in`, the calendar pane through `cal`, and the clock pane through `toilet` or `figlet`. These features were reintroduced from remembered behavior and later validated against the output of the older Arch system.

How this was implemented was by extending the declarative splash script and adding the corresponding packages to the Home Manager environment. The splash now composes three aligned blocks after the fortune section, using temporary files and `paste` to reproduce the side-by-side layout of the earlier shell dashboard.

Why these additions matter is that shell startup, in this environment, serves as a compact operational dashboard rather than mere ornamentation. Local weather, calendar position, and current time each provide immediate situational information before any further command is entered.

## Departure From The 1990s Separator Style

At this point the splash ceased to be merely a direct port of a long-lived shell habit and became an intentional redesign. The older `sep` motif of repeated horizontal divider lines had served well for decades, but it encoded an era of terminal presentation that was more austere than necessary for a current workstation.

What changed here was the visual language of the login display. The startup view was reorganized into boxed sections with a more deliberate hierarchy: machine state, session index, a quotation block, and a three-column field board for weather, calendar, and time. Unicode box-drawing glyphs were preferred when the locale supported them, with plain ASCII retained as fallback.

How this was implemented was by rewriting the splash script around a small set of layout primitives instead of repeated ad hoc separators. The retained informational content was not discarded, but it was framed in a way that reads more like a compact operations dashboard than a shell script inherited from the 1990s.

Why this redesign matters is that preservation of habit should not prevent improvement of form. The goal of the new splash is still continuity with the older environment, but expressed through a cleaner and more intentional terminal aesthetic appropriate to the present machine.

## Migration To A Flake-Based System

The next structural change was a migration from a non-flake NixOS configuration to a flake-based one. Up to this point, the system was already declarative, but its entrypoint still relied on ambient evaluation conventions and an in-file `fetchTarball` for Home Manager.

What changed was the introduction of `/etc/nixos/flake.nix` and the creation of a corresponding `flake.lock`. The existing `configuration.nix`, `home.nix`, and `hardware-configuration.nix` files were retained, but the source of truth for package inputs and Home Manager integration moved into the flake. The system therefore became a named output, rebuilt as `callisto` rather than as an implicitly evaluated directory.

How this was done was intentionally conservative. Instead of redesigning the entire tree, the existing module layout was preserved and wrapped in a minimal flake that pinned `nixpkgs` and `home-manager` at explicit revisions. The old `fetchTarball` import was then removed from `configuration.nix`, and the rebuild path changed to `sudo nixos-rebuild switch --flake /etc/nixos#callisto`.

Why this migration matters is primarily provenance. The configuration now declares not only what the machine should be, but also the exact upstream inputs from which that state is evaluated. In conceptual terms, this moves the system closer to a pinned and materialized graph model: named outputs with explicit upstream dependencies rather than a correct but more ambient evaluation style.

## Adjustment Of Helper Workflows To The Flake Entry Point

The move to flakes changed more than the rebuild command. It also exposed a mismatch in the helper scripts that had accumulated during earlier configuration work.

What changed was the behavior of local convenience tooling, especially the `nsi` helper in `~/.local/bin`. Before the migration, that script edited `/etc/nixos/home.nix` and then triggered a plain `sudo nixos-rebuild switch`, which was appropriate only in the older non-flake model.

How this was corrected was by updating the helper so that both its documentation and its execution path rebuild through the flake output, specifically `sudo nixos-rebuild switch --flake /etc/nixos#callisto`. The script had already been improved to reject option-like arguments, validate package names against `nixpkgs`, detect duplicates, and skip rebuilds if no configuration change occurred. The flake migration therefore required only that its final activation step be brought into alignment with the new configuration topology.

Why this adjustment mattered is that workflow drift can quietly reintroduce ambiguity even after the underlying system has been cleaned up. A flake-based system is most useful when both its formal configuration and its everyday helper commands agree on the same entrypoint and identity.

## Refactoring Of Home Manager Into A Module Tree

Once the system was flake-based, attention returned to the internal structure of Home Manager itself. The file `/etc/nixos/home.nix` had become functional but swollen. It mixed package declarations, shell setup, tmux behavior, editor linkage, environment variables, and the entire terminal splash implementation in one large file.

What changed was the decomposition of this monolithic Home Manager file into a set of focused modules under `/etc/nixos/home/`. The top-level `home.nix` was reduced to user identity, state version, Home Manager enablement, and an import of the module tree. Separate files were created for packages, session variables, `zsh`, `tmux`, `atuin`, `broot`, `lsd`, AstroNvim linkage, and splash installation. The splash script and tmux powerline theme were also moved out of inline Nix strings into real files under `/etc/nixos/home/files/`.

How this was done was by preserving behavior and changing only the configuration shape. Existing logic was copied into focused modules rather than rewritten semantically. The splash script remained the same dashboard logic, but it ceased to be buried inside a quoted Nix string. Likewise, the tmux powerline theme became a first-class file installed through `xdg.configFile` rather than an embedded blob.

Why this refactor matters is that declarative configuration should still be readable as engineering infrastructure. A large inline string is tolerable during experimentation, but it scales poorly. By converting `home.nix` into a composition layer and moving operational payloads into files, the system became easier to navigate, easier to audit, and easier to modify without introducing quoting or escaping errors.
