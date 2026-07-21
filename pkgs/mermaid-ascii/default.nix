{
buildGoModule,
fetchFromGitHub,
}:

buildGoModule {
  pname = "mermaid-ascii";
  version = "0-unstable-2025-06-16";

  src = fetchFromGitHub {
    owner = "AlexanderGrooff";
    repo = "mermaid-ascii";
    rev = "fe11b41d4687b647f82aea1cf8fe5802fa6f5541";
    hash = "sha256-U9gEF3nEzaJWAXLfn+ihfLjL4QZj/TVmnvDU0OBcQUA=";
  };

  vendorHash = "sha256-aB9sbTtlHbptM2995jizGFtSmEIg3i8zWkXz1zzbIek=";

  doCheck = false;
}
