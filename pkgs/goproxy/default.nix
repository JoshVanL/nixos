{ lib
, buildGoModule
, fetchFromGitHub
}:

buildGoModule rec {
  pname = "goproxy";
  version = "0.16.3";

  src = fetchFromGitHub {
    owner = "goproxy";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-XNoJP7wkBRKQposgs95k1Y6KoBmk8XUHX2/4Kjjhz0s=";
  };

  vendorHash = "sha256-7KpNSMzTOhTKmD/Gh6XDOu2qCACwVMwFrYqowW8wVLk=";
  doCheck = false;

  meta = with lib; {
    homepage = "https://github.com/goproxy/goproxy";
    description = "A minimalist Go module proxy handler.";
    longDescription = ''
      A minimalist Go module proxy handler.
    '';
    license = licenses.mit;
  };
}
