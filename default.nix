{ user ? throw "Need user"
, path ? throw "need path"
, packages ? [ ]
, env ? [ ]
}:
let
  pkgs = import ./packages.nix;
  sandbox = import ./sandbox.nix;

  packageDerivations = map (package: pkgs.${package}.bin) packages;
in
sandbox.sandboxExes { inherit user path env; paths = packageDerivations; }
