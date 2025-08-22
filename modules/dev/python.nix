{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.me.dev.python;

  pythonPackages = py: py.withPackages(ps: with ps; [
    flask
    pip
    grpcio-tools
    #uvicorn
    #fastapi
    #typing-extensions
    #requests
    #pydantic
    #grpcio
    virtualenv
    #(
    #  buildPythonPackage rec {
    #    pname = "cloudevents";
    #    version = "1.10.0";
    #    pyproject = true;
    #    build-system = [ setuptools ];
    #    src = fetchPypi {
    #      inherit pname version;
    #      sha256 = "sha256-DE9yUBJnlTv3xsZROSFgKvzaAmgiAsZd6qur7AmFZzE=";
    #    };
    #    doCheck = false;
    #  }
    #)
    #(
    #  buildPythonPackage rec {
    #    pname = "dapr";
    #    version = "1.14.0";
    #    pyproject = true;
    #    build-system = [ setuptools ];
    #    src = fetchPypi {
    #      inherit pname version;
    #      sha256 = "sha256-2QG3h6UVT0tORI5DmCVpPzNS3aN0iJ71QSgd0nJ7jWE=";
    #    };
    #    doCheck = false;
    #  }
    #)
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
