# [nixos](https://www.stilldrinking.org/programming-sucks) 

- `/machines` root machine configurations;
- `/modules` modules used by the machines;
- `/apps` runnable apps, used for installing and managing machines;
- `/pkgs` software packages that are not in nixpkgs;
- `/overlays` overlays for nixpkgs.

Machines use zfs where all data is shredded on boot unless stored (or sys
linked) from `/persist` or `/keep`. `/persist` is intended to be backed up.

## To install

Boot from a [nixos image](https://nixos.org/download.html) and [setup internet
connectivity](https://nixos.wiki/wiki/NixOS_Installation_Guide#Wireless). Follow
the installer application's instructions.

```bash
$ nix run --experimental-features 'nix-command flakes' github:joshvanl/nixos
```

After you have installed, rebooted & logged in, run:

```bash
$ sudo nix run /keep/etc/nixos#post-install
```

### Options

Install a specific commit:

```bash
$ nix run --experimental-features 'nix-command flakes' github:joshvanl/nixos/9914fa7
```

When installing from a different repo, ensure the `NIXOS_REPO` environment
variable is set:

```bash
$ NIXOS_REPO='notme/diffnixos' sudo nix run --experimental-features 'nix-command flakes' github:notme/diffnixos
```
