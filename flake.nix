{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    joshvanldwm = {
      url = "github:joshvanl/dwm";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-serve-ng = {
      url = "github:aristanetworks/nix-serve-ng";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    xpropdate = {
      url = "github:joshvanl/xpropdate";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    imgs = {
      url = "github:joshvanl/imgs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, ... }@inputs:
  let
    modules = import ./modules {inherit self nixpkgs inputs; };
  in modules;
}
