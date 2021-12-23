{ lib, pkgs, applyPatches }:

pkgs.stdenv.mkDerivation rec {
  pname = "somebar";
  version = "1.0.0";

  src = pkgs.fetchFromGitHub {
    owner = "joshvanl";
    repo = pname;
    rev = "85b7b6290aff2c121dc6ced132f3e3d13ebb3ec6";
    hash = "sha256-2gp+NO8vJ5c56NyMuGFfSjN232F09dFVExRzC5nkWvI=";
  };

  nativeBuildInputs = [ pkgs.pkg-config pkgs.meson pkgs.ninja ];

  buildInputs = [
    pkgs.gcc
    pkgs.cairo
    pkgs.wayland
    pkgs.wayland-protocols
    pkgs.pango
  ];

  dontBuild = true;
  dontConfigure = true;

  patches = applyPatches;

  installPhase = ''
    runHook preInstall
    meson build --fatal-meson-warnings
    cp src/config.def.hpp src/config.hpp
    cd build
    ninja
    mkdir -p $out/bin
    cp ./somebar $out/bin/somebar
    runHook postInstall
  '';

  meta = with lib; {
    homepage = "https://git.sr.ht/~raphi/somebar";
    description = "dwm-like bar for dwl";
    longDescription = ''
      dwm-like bar for dwl.
    '';
    license = licenses.mit;
    inherit (pkgs.wayland.meta) platforms;
  };
}
