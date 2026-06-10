final: prev: {
  claude-code = let
    version = "2.1.170";

    sources = {
      "x86_64-linux" = {
        suffix = "linux-x64";
        hash = "sha256-boRtO4oV/PP30bB0wWKYyuR2woZV3joAvqyxpiL6txs=";
      };
      "aarch64-linux" = {
        suffix = "linux-arm64";
        hash = "sha256-ULg8/2OXW+mBbmJhVm1VHYUmQ2cc5ynHMQ68f3JTBBI=";
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
