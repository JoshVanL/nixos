final: prev: {
  claude-code = let
    version = "2.1.303";

    sources = {
      "x86_64-linux" = {
        suffix = "linux-x64";
        hash = "sha256-MlwsQRWKs+y+C4GqPsi43AUpvQNWyeLfG4k/Y2MzwJg=";
      };
      "aarch64-linux" = {
        suffix = "linux-arm64";
        hash = "sha256-g2RemZw9En8gJ6FpGtUsf8N6S31erEJh5Y0GRbSBtJg=";
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
