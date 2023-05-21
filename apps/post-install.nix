{ lib }:
with lib;

let
  post-install = system: (pkgsys system).writeShellApplication {
    name = "port-install.sh";
    runtimeInputs = with (pkgsys system); [
      coreutils
      util-linux
      nix
      git
      systemdMinimal
    ];
    text = ''
      ${loggerFuncsString}
      ${mustBeRootString}

      declare -A USERNAMES_MAP=(${usernamesBashMap})
      USERNAME="''${USERNAMES_MAP[$(hostname)]}"

      info "Changing ownership of /keep/etc/nixos to $USERNAME ..."
      chown -R "$USERNAME":wheel /keep/etc/nixos

      info "Changing ownership of /persist/home to $USERNAME ..."
      chown -R "$USERNAME":wheel /persist/home

      info "Switching nixos configuration ..."
      nixos-rebuild switch -L --flake '/keep/etc/nixos/.#'

      info "Ready. Rebooting ..."
      read -r -p "Press any key to continue ..."
      reboot
    '';
  };


in listToAttrs (map (system:
  nameValuePair "${system}" {post-install = mkApp (post-install system);}
) targetSystems)
