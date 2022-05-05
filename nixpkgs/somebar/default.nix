with import <nixpkgs> {}; # bring all of Nixpkgs into scope

let
  totalPatches = [
    (fetchpatch {
      name = "somebar.ipc";
      url  = "https://raw.githubusercontent.com/JoshVanL/somebar/master/contrib/ipc.patch";
      hash = "sha256-+aXA9CcP729cuxpfUqL4HWsITjFW8USs5xs3Lv673C4=";
    })
  ];
in

stdenv.mkDerivation rec {
  pname = "somebar";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "joshvanl";
    repo = pname;
    rev = "85b7b6290aff2c121dc6ced132f3e3d13ebb3ec6";
    hash = "sha256-2gp+NO8vJ5c56NyMuGFfSjN232F09dFVExRzC5nkWvI=";
  };

  nativeBuildInputs = [ pkg-config meson ninja ];

  buildInputs = [
    gcc
    cairo
    wayland
    wayland-protocols
    pango
  ];

  dontBuild = true;
  dontConfigure = true;

  patches = totalPatches;

  installPhase = ''
    meson build --fatal-meson-warnings
    cp src/config.def.hpp src/config.hpp
    cd build
    ninja
    mkdir -p $out/bin
    cp ./somebar $out/bin/somebar
  '';

  meta = with lib; {
    homepage = "https://git.sr.ht/~raphi/somebar";
    description = "dwm-like bar for dwl";
    longDescription = ''
      dwm-like bar for dwl.
    '';
    license = licenses.mit;
    inherit (wayland.meta) platforms;
  };
}
