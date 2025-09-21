{
  outputs = { self }:
    let
      libFor = system: {
        lib = import ./lib.nix { inherit system; };
        pkgs = import ./packages.nix { inherit system; };
        sandbox = import ./sandbox.nix { lib = self.lib.${system}.lib; };
        shellWithPackages = { packageNames }: self.lib.${system}.sandbox.sandboxExes {
          paths = map (package: self.lib.${system}.pkgs.${package}.bin) packageNames;
        };
      };
    in

    {
      lib.aarch64-darwin = libFor "aarch64-darwin";
      packages.aarch64-darwin.foo = self.lib.aarch64-darwin.pkgs.nsc.bin;
      packages.aarch64-darwin.shell = self.lib.aarch64-darwin.shellWithPackages { packageNames = [ "python" "nodejs" ]; };
    };
}
