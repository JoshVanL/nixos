final: prev: {
  claude-code = prev.stdenv.mkDerivation rec {
    pname = "claude-code";
    version = "2.1.72";

    src = prev.fetchzip {
      url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
      hash = "sha256-sSIjVW0DWb/rTv0AN7ineU4h45jnzFfElqkr1/+wWAk=";
    };

    nativeBuildInputs = [ prev.makeWrapper ];

    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin $out/lib/node_modules/@anthropic-ai/claude-code
      cp -r * $out/lib/node_modules/@anthropic-ai/claude-code/

      makeWrapper ${prev.nodejs}/bin/node $out/bin/claude \
        --add-flags "$out/lib/node_modules/@anthropic-ai/claude-code/cli.js" \
        --set DISABLE_AUTOUPDATER 1 \
        --set DISABLE_AUTO_MIGRATE_TO_NATIVE 1 \
        --unset DEV

      runHook postInstall
    '';

    meta = prev.claude-code.meta or {};
  };
}
