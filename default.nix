{ packages ? [ ] }:
let
  pkgs = import ./packages.nix;
  sandbox = import ./sandbox.nix;
  packageDerivations = map (package: pkgs.${package}.bin) packages;
in
sandbox.sandboxExes { paths = packageDerivations; }
