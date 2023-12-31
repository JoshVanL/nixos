{ lib
, buildGoModule
, fetchFromGitHub
}:

buildGoModule rec {
  pname = "gomarkdoc";
  version = "1.1.0";

  src = fetchFromGitHub {
    owner = "princjef";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-eMH+F1ZXAKHqnrvOJvCETm2NiDwY03IFHrDNYr3jaW8=";
  };

  vendorHash = "sha256-gCuYqk9agH86wfGd7k6QwLUiG3Mv6TrEd9tdyj8AYPs=";
  subPackages = [ "cmd/gomarkdoc" ];
  meta = with lib; {
    homepage = "https://github.com/princjef/gomarkdoc";
    description = " Generate markdown documentation for Go (golang) code";
    longDescription = ''
      Package gomarkdoc formats documentation for one or more packages as
      markdown for usage outside of the main https://pkg.go.dev site. It
      supports custom templates for tweaking representation of documentation at
      fine-grained levels, exporting both exported and unexported symbols, and
      custom formatters for different backends.
    '';
    license = licenses.mit;
  };
}
