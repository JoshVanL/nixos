final: prev: {
  claude-code = let
    version = "2.1.153";

    sources = {
      "x86_64-linux" = {
        suffix = "linux-x64";
        hash = "sha256-kOXcCui5jMCIJgelpuWUjfv2tkupCBBuw9KLKs6JCv4=";
      };
      "aarch64-linux" = {
        suffix = "linux-arm64";
        hash = "sha256-h87rkOK5XhM6ayZX68zEraqbaQ91wg+6WZS88fUJ3oc=";
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
