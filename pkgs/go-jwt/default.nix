{ lib
, buildGoModule
, fetchFromGitHub
}:

buildGoModule rec {
  pname = "jwt";
  version = "5.2.0";

  src = fetchFromGitHub {
    owner = "golang-jwt";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-KlZoiRRn4ER2z8r8CBmJ9dKoWTYjZEZ/kRL/2uAXoV8=";
  };

  vendorHash = null;

  doCheck = false;

  meta = with lib; {
    homepage = "https://github.com/golang-jwt/jwt";
    description = "Community maintained clone of https://github.com/dgrijalva/jwt-go";
    longDescription = ''
      A go (or 'golang' for search engine friendliness) implementation of JSON
      Web Tokens.
    '';
    license = licenses.mit;
  };
}
