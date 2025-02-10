final: prev: {
  bitwarden-cli = prev.bitwarden-cli.overrideAttrs (oldAttrs: rec {
    npmRebuildFlags = [
      # FIXME one of the esbuild versions fails to download @esbuild/linux-x64
      "--ignore-scripts"
    ];
    postInstall = ''
      # Clean up broken symlinks.
      find "$out"/lib/node_modules/ -xtype l -delete
    '';
  });
}

