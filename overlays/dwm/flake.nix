{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    let
      targetSystems = [ "x86_64-linux" "aarch64-linux" ];
      patches = [
        ./patches/gaps.patch
        ./patches/toggle-layout.patch
        ./patches/master-right.patch
        ./patches/rotatestack.patch
        ./patches/config.patch
      ];
      dwmOverlay = final: prev: {
        dwm-joshvanl = prev.dwm.overrideAttrs (_: {
          src = ./.;
          patches = patches;
        });
      };

    in flake-utils.lib.eachSystem targetSystems (system: let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ dwmOverlay ];
      };
    in rec {
      packages.default = pkgs.dwm-joshvanl;
      checks = packages;
    }) // rec {
      overlays.default = final: prev: {
        dwm = final.dwm-joshvanl;
      };
      nixosModules.default = {
        nixpkgs.overlays = [ dwmOverlay overlays.default ];
      };
    };
}
