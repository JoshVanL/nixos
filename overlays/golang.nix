final: prev:
{
  # For pkgs whose go.mod needs a newer Go than nixpkgs' go_1_26 (catalyst-cron,
  # cdpr). Drop this once go_1_26 catches up.
  go_1_26_latest = prev.go_1_26.overrideAttrs (old: rec {
    version = "1.26.10";
    src = prev.fetchurl {
      url = "https://go.dev/dl/go${version}.src.tar.gz";
      hash = "sha256-/WPog7ovK/ypPBZGsx6+9j4rHk0rMXyXidl2po2B828=";
    };
  });
}
