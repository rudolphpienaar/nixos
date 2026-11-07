# NixOS workstations

One lockfile and software profile serve two machines:

| Host | Configuration | Hardware |
| --- | --- | --- |
| `callisto` | `configuration.nix` | Existing AMD system, NYC networking and NexDock settings |
| `vendian` | `hosts/vendian/default.nix` | Intel i5-10500T, Falmouth, `10.0.0.25` |

`modules/workstation.nix` defines the shared GNOME desktop, packages, services,
and accounts. `home/` defines Rudolph's shared user environment. Each host owns
its hardware configuration, hostname, installation state version, and site settings.
Keep the hardware configuration and state version belonging to each machine.
The automatic Mercury SSH tunnel is enabled only on Callisto, whose NYC network
can reach Mercury's private address. Vendian does not start that tunnel.

## Normal use

Keep a checkout at `/home/rudolph/dev/nixos`. On either machine:

```sh
cd /home/rudolph/dev/nixos
git pull --ff-only
nsr
```

`nsr` selects the running machine's hostname. To rebuild explicitly:

```sh
sudo nixos-rebuild switch --flake /home/rudolph/dev/nixos#callisto
# Or, on Vendian:
sudo nixos-rebuild switch --flake /home/rudolph/dev/nixos#vendian
```

## Vendian's first activation

The existing `toor` administrator and password are preserved. The new `rudolph`
account uses UID 2090878 and group `fnndsc` (GID 1102), matching Callisto. Both
accounts authorize the public key in `keys/rudolph.pub`; no private keys are stored
here. As on Callisto, the shared profile enables passwordless sudo for wheel.

The installer configuration is backed up at `/etc/nixos.bak`, with an additional
copy at `/home/toor/nixos-install-backup`.
From the staged checkout, run as `toor`:

```sh
sudo nixos-rebuild switch --flake /home/toor/nixos#vendian \
  --option experimental-features 'nix-command flakes' --cores 4 --max-jobs 2
sudo passwd rudolph
```

The password command enables Rudolph's local/graphical login; SSH uses the
authorized key. After activation, install the normal checkout under
`/home/rudolph/dev/nixos` and the separate editor checkout under
`/home/rudolph/dev/avim` (upstream: `https://github.com/rudolphpienaar/avim.git`).
Callisto's editor checkout, including its local changes, is staged at
`/home/toor/avim` for installation after activation.
The shared Home Manager configuration links to that editor directory.

The repo reproduces its declared environment. Personal files, application data,
SSH private keys, Wi-Fi credentials, and undeclared desktop preferences are not
copied by a rebuild. Vendian retains its existing NetworkManager connection.
Its second, encrypted disk is left unconfigured and unmounted.
