{ lib
, buildGoModule
, fetchFromGitHub
}:

buildGoModule rec {
  pname = "jwt";
  version = "4.5.0";

  src = fetchFromGitHub {
    owner = "golang-jwt";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-dyKL8wQRApkdCkKxJ1knllvixsrBLw+BtRS0SjlN7NQ=";
  };

  vendorSha256 = null;

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
