
let
  sandbox = import ./sandbox.nix;
  packages = import ./packages.nix;
in
{ nodejs_sandbox = sandbox.sandboxExes { 
