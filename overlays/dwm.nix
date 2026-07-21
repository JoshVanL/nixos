final: prev: {
  # Vendored from github:joshvanl/dwm (rev d084aba). Source and patches live in
  # ./dwm so they can be edited here without the external repo.
  dwm = prev.dwm.overrideAttrs (_: {
    src = ./dwm;
    patches = [
      ./dwm/patches/gaps.patch
      ./dwm/patches/toggle-layout.patch
      ./dwm/patches/master-right.patch
      ./dwm/patches/rotatestack.patch
      ./dwm/patches/config.patch
    ];
  });
}
