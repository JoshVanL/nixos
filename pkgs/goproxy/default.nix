{ lib
, buildGoModule
, fetchFromGitHub
}:

buildGoModule rec {
  pname = "goproxy";
  version = "0.13.0";

  src = fetchFromGitHub {
    owner = "goproxy";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-k6BtPRIRaj2Jb/qKmhKYSDbF/eZ6oCMLiKoTwFqvgh0=";
  };

  vendorSha256 = "sha256-A4aUrb0y+bUFYDZMRsfqN/SVAHWAAGkHBF+dovlASwI=";
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
