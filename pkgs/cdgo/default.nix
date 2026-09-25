{ buildGoModule
, installShellFiles
, lib
}:

buildGoModule {
  pname = "cdgo";
  version = "0.1.0";

  src = ./.;
  vendorHash = "sha256-7K17JaXFsjf163g5PXCb5ng2gYdotnZ2IDKk8KFjNj0=";

  nativeBuildInputs = [ installShellFiles ];
  postInstall = ''
    installShellCompletion --cmd cdgo \
      --zsh <($out/bin/cdgo completion zsh)
  '';

  meta = with lib; {
    description = "Disposable multi-repo claude workspaces, sandboxes, and background jobs";
    mainProgram = "cdgo";
  };
}
