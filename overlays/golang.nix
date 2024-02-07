final: prev: rec {
  go = prev.go_1_21;

  # `gocode` is fully deprecated, so replace it with a benign package.
  gocode = go;
}
