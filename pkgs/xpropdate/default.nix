{ buildGoModule, writeShellApplication, xprop }:
# Vendored from github:joshvanl/xpropdate (rev 55d084c) so it builds
# against this repo's nixpkgs.
let
  bin = buildGoModule {
    pname = "xpropdate";
    version = "0-unstable-2024-01-16";
    src = ./.;
    vendorHash = null;
  };
in writeShellApplication {
  name = "xpropdate";
  runtimeInputs = [ xprop ];
  text = ''
    exec ${bin}/bin/xpropdate
  '';
}
