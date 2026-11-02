{ lib
, stdenv
, fetchurl
, autoPatchelfHook
, installShellFiles
}:

let
  version = "1.118.0";
  bucket = "bkt-p-cli-common-us-central1-95640";
  sysMap = {
    x86_64-linux = { os = "linux"; arch = "amd64"; hash = "sha256-XGPCve7xXwEQqJYcIPs1F3YMOrJV2yiJDHQ5uUXsrkg="; };
    aarch64-linux = { os = "linux"; arch = "arm64"; hash = "sha256-v81vTECYxzmdVZQDBThPRNkDSTN7f4NK8QJ+8m04W34="; };
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

  nativeBuildInputs = [ autoPatchelfHook installShellFiles ];
  buildInputs = [ stdenv.cc.cc.lib ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    tar -xzf $src -C $out/bin
    chmod +x $out/bin/diagrid
    runHook postInstall
  '';

  postInstall = ''
    run="$(cat $NIX_CC/nix-support/dynamic-linker) --library-path ${lib.makeLibraryPath [ stdenv.cc.cc.lib ]} $out/bin/diagrid"
    installShellCompletion --cmd diagrid \
      --bash <(HOME=$TMPDIR $run completion bash) \
      --zsh <(HOME=$TMPDIR $run completion zsh) \
      --fish <(HOME=$TMPDIR $run completion fish)
  '';

  meta = with lib; {
    description = "Diagrid CLI for managing Catalyst and Conductor resources";
    homepage = "https://docs.diagrid.io";
    platforms = builtins.attrNames sysMap;
    mainProgram = "diagrid";
  };
}
