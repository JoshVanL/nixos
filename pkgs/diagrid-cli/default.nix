{ lib
, stdenv
, fetchurl
, autoPatchelfHook
}:

let
  version = "0.634.0";
  bucket = "bkt-p-cli-common-us-central1-95640";
  sysMap = {
    x86_64-linux = { os = "linux"; arch = "amd64"; hash = "sha256-fwYI661Kb2GTe41rUjdqN1l+/SLiXNLKrAQZjZ+yWl8="; };
    aarch64-linux = { os = "linux"; arch = "arm64"; hash = "sha256-BhBLg2/nZuJDvko1a7XlCXX47+XYSkY9pCMfsSYbxbo="; };
  };
  plat = sysMap.${stdenv.hostPlatform.system};
  name = "diagrid_${plat.os}_${plat.arch}";
in

stdenv.mkDerivation {
  pname = "diagrid-cli";
  inherit version;

  src = fetchurl {
    url = "https://storage.googleapis.com/${bucket}/v${version}/diagrid/${name}/${name}.tar.gz";
    hash = plat.hash;
  };

  dontUnpack = true;

  nativeBuildInputs = [ autoPatchelfHook ];
  buildInputs = [ stdenv.cc.cc.lib ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    tar -xzf $src -C $out/bin
    chmod +x $out/bin/diagrid
    runHook postInstall
  '';

  meta = with lib; {
    description = "Diagrid CLI for managing Catalyst and Conductor resources";
    homepage = "https://docs.diagrid.io";
    platforms = builtins.attrNames sysMap;
    mainProgram = "diagrid";
  };
}
