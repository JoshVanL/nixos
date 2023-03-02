{ lib
, buildGoModule
, fetchFromGitHub
}:

buildGoModule rec {
  pname = "shadow";
  version = "0.11.0";

  src = fetchFromGitHub {
    owner = "golang";
    repo = "tools";
    rev = "gopls/v${version}";
    hash = "sha256-49TDAxFx4kSwCn1YGQgMn3xLG3RHCCttMzqUfm4OPtE=";
  };

  subPackages = [ "go/analysis/passes/shadow/cmd/shadow" ];

  vendorSha256 = "sha256-EQHYf4Q+XNjwG/KDoTA4m0mlBGxPkJSLUcO0VHFSpeA=";

  meta = with lib; {
    homepage = "https://pkg.go.dev/golang.org/x/tools";
    description = "[mirror] Go Tools";
    longDescription = ''
      This repository provides the golang.org/x/tools module, comprising
      various tools and packages mostly for static analysis of Go programs,
      some of which are listed below. Use the "Go reference" link above for
      more information about any package.
    '';
    license = licenses.bsd3;
  };
}
