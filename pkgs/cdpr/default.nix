{ buildGoModule
, gh
, git
, go_1_26_latest
, lib
, makeWrapper
}:

# Installed by the cdgo module (modules/shell/cdgo), whose cdpr shell function
# runs __cdpr and whose __cdgo and __cdgo_sandbox it finds on PATH.
(buildGoModule.override { go = go_1_26_latest; }) {
  pname = "cdpr";
  version = "0.1.0";

  src = ./.;
  vendorHash = "sha256-7K17JaXFsjf163g5PXCb5ng2gYdotnZ2IDKk8KFjNj0=";

  nativeBuildInputs = [ makeWrapper ];
  postInstall = ''
    mv $out/bin/cdpr $out/bin/__cdpr
    wrapProgram $out/bin/__cdpr --prefix PATH : ${lib.makeBinPath [ git gh ]}
  '';

  meta = {
    description = "Check out a GitHub pull request in a cdgo workspace, to review it locally";
    mainProgram = "__cdpr";
  };
}
