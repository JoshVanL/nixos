final: prev: {
  dapr-cli = prev.buildGoModule rec {
  pname = "dapr-cli";
  version = "1.10.0";

  src = prev.fetchFromGitHub {
    owner = "dapr";
    repo = "cli";
    rev = "v${version}";
    sha256 = "sha256-LBsJjAtsKlecRhes9q+HYCwlhZn0jUhhEzu62nATGz8=";
  };

  vendorSha256 = "sha256-8xRU/CJMP39U/sXug17ck5cHPz5ujFU/XKpGnEq93tg=";

  nativeBuildInputs = [ prev.installShellFiles ];

  subPackages = [ "." ];

  preCheck = ''
    export HOME=$(mktemp -d)
  '';

  ldflags = [
    "-X main.version=${version}"
    "-X main.apiVersion=1.0"
    "-X github.com/dapr/cli/pkg/standalone.gitcommit=${src.rev}"
    "-X github.com/dapr/cli/pkg/standalone.gitversion=${version}"
  ];

  postInstall = ''
    mv $out/bin/cli $out/bin/dapr

    installShellCompletion --cmd dapr \
      --bash <($out/bin/dapr completion bash) \
      --zsh <($out/bin/dapr completion zsh)
  '';

  meta = with prev.lib; {
    description = "A CLI for managing Dapr, the distributed application runtime";
    homepage = "https://dapr.io";
    license = licenses.mit;
    maintainers = with maintainers; [ joshvanl lucperkins ];
    mainProgram = "dapr";
  };
};

}
