{ lib }:

with lib;

let
  post-install = system: (pkgsys system).writeShellApplication {
    name = "port-install.sh";
    runtimeInputs = with (pkgsys system); [ nix git zfs ];
    text = ''
      echo "${system}"
    '';
  };


in listToAttrs (map (system:
  nameValuePair "${system}" {post-install = mkApp (post-install system);}
) targetSystems)
