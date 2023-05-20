# [nixos](https://www.stilldrinking.org/programming-sucks)

- `/machines` root machine configurations.
- `/modules` modules used by the machines.
- `/scripts` scripts used to install a machines.
- `/pkgs` software packages that are not in nixpkgs.
- `/overlays` overlays for nixpkgs.

Machines use zfs where all data is shredded on boot unless stored (or sys
linked) from `/persist` or `/keep`. `/persist` is intended to be backed up.

## To install

Boot from a [nixos image](https://nixos.org/download.html), then:

```bash
$ sudo -i
$ # Setup internet connectivity (https://nixos.wiki/wiki/NixOS_Installation_Guide#Wireless)
$ nix-shell -p git
$ git clone https://github.com/joshvanl/nixos
$ cd nixos && ./scripts/install.sh
$ # Follow install instructions
```

After you have installed, rebooted and logged in, run:

```bash
$ sudo /etc/nixos/scripts/post-install.sh
```
