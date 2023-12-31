{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.me.dev.python;

  pythonPackages = py: py.withPackages(ps: with ps; [
    flask
    pip
    (
      buildPythonPackage rec {
        pname = "cloudevents";
        version = "1.10.0";
        src = fetchPypi {
          inherit pname version;
          sha256 = "sha256-DE9yUBJnlTv3xsZROSFgKvzaAmgiAsZd6qur7AmFZzE=";
        };
        doCheck = false;
      }
    )
    (
      buildPythonPackage rec {
        pname = "dapr";
        version = "1.12.1";
        src = fetchPypi {
          inherit pname version;
          sha256 = "sha256-QtydNCLf9E+Gzywwv7NvwGKYKshmp89ovBwfSCMnO8I=";
        };
        doCheck = false;
      }
    )
  ]);

in {
  options.me.dev.python = {
    enable = mkEnableOption "dev.python";
  };

  config = mkIf cfg.enable {
    home-manager.users.${config.me.username}.home.packages = with pkgs; [
      (pythonPackages python3)
    ];
  };
}
