final: prev: {
  claude-code = let
    version = "2.1.168";

    sources = {
      "x86_64-linux" = {
        suffix = "linux-x64";
        hash = "sha256-y9CmxTdYcYxPPEzp2lUrmHiSSzz67M3zRerYc7GO49Q=";
      };
      "aarch64-linux" = {
        suffix = "linux-arm64";
        hash = "sha256-SUo2qcgXBPrcTOtc1fWNTLzLFreV6ZBopoLPNsENKek=";
      };
    };

    source = sources.${prev.stdenv.hostPlatform.system}
      or (throw "claude-code: unsupported system ${prev.stdenv.hostPlatform.system}");
  in prev.stdenv.mkDerivation {
    pname = "claude-code";
    inherit version;

    src = prev.fetchzip {
      url = "https://registry.npmjs.org/@anthropic-ai/claude-code-${source.suffix}/-/claude-code-${source.suffix}-${version}.tgz";
      hash = source.hash;
    };

    nativeBuildInputs = [ prev.autoPatchelfHook prev.makeWrapper ];
    buildInputs = [ prev.stdenv.cc.cc.lib ];

    dontStrip = true;

    installPhase = ''
      runHook preInstall

      install -Dm755 claude $out/bin/claude

      runHook postInstall
    '';

    postFixup = ''
      wrapProgram $out/bin/claude \
        --set DISABLE_AUTOUPDATER 1 \
        --set DISABLE_AUTO_MIGRATE_TO_NATIVE 1 \
        --set DISABLE_INSTALLATION_CHECKS 1 \
        --unset DEV
    '';

    meta = prev.claude-code.meta or {};
  };
}
