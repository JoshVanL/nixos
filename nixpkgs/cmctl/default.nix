{ lib
, buildGo118Module
, fetchFromGitHub
}:

buildGo118Module rec {
  pname = "cmctl";
  version = "1.8.0";

  src = fetchFromGitHub {
    owner = "cert-manager ";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-GrJ48q4RxvMHr3z7V37LLyuaok5VNGOq+HEhay+/gMA=";
  };

  vendorSha256 = "sha256-/UDmTyngydoso9F/iPp5JYlsfi0VNfHfTsxdGDaTK+w=";
  subPackages = [ "./cmd/cmctl" ];

  postInstall = ''
    mkdir -p $out/share/{bash-completion/completions,zsh/site-functions}
    $out/bin/cmctl completion bash > $out/share/bash-completion/completions/cmctl
    $out/bin/cmctl completion zsh > $out/share/zsh/site-functions/_cmctl
  '';

  meta = with lib; {
    homepage = "cert-manager.io";
    description = "TODO";
    longDescription = ''
      TODO
    '';
    license = licenses.asl20;
  };
}
