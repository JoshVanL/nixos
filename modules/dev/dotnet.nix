{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.me.dev.dotnet;

in {
  options.me.dev.dotnet = {
    enable = mkEnableOption "dev.dotnet";
  };

  config = mkIf cfg.enable {
    programs.nix-ld.enable = true;
    home-manager.users.${config.me.username} = {
      programs.neovim = {
        plugins = with pkgs.vimPlugins; [
          vim-csharp
        ];
      };

      home = {
        packages = with pkgs.dotnetCorePackages; [
          sdk_7_0
        ];
        sessionVariables = {
          DOTNET_ROOT = "${pkgs.dotnet-sdk}";
          NIX_LD_LIBRARY_PATH = lib.makeLibraryPath ([
            pkgs.stdenv.cc.cc
          ]);
          NIX_LD = "${pkgs.stdenv.cc.libc_bin}/bin/ld.so";

          # Breath in, breath out.
          DOTNET_CLI_TELEMETRY_OPTOUT = "1";
        };
      };
    };
  };
}
