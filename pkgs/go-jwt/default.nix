{ lib
, buildGo119Module
, fetchFromGitHub
}:

buildGo119Module rec {
  pname = "jwt";
  version = "4.4.1";

  src = fetchFromGitHub {
    owner = "golang-jwt";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-aq8G0baDZks5LXCVbufU1J/r0AMgD2TcZez326G2PEA=";
  };

  vendorSha256 = "sha256-pQpattmS9VmO3ZIQUFn66az8GSmB4IvYhTTCFn6SUmo=";
  subPackages = [ "cmd/jwt" ];

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
