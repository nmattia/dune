let
  lib = import ./lib.nix;
  packages = import ./packages.nix;
  pkgs = import <nixpkgs> { };
in
rec {

  sandboxExeWrapper = { paths, }: pkgs.writeScriptBin "sandbox-wrapper" ''
    #!/usr/bin/env bash

    set -euo pipefail

    DUNE_UNTRUSTED_PATH=${builtins.concatStringsSep ":" paths} \
        DUNE_EXE_NAME="$(basename "$0")" \
        DUNE_SANDBOX_DIR="$(dirname "$0")" \
        DUNE_SANDBOXER=${./sandboxer} \
        exec ${./dune-runner} "$@"
  '';

  # note: if called directly, 'paths' should be strings for things like /bin, _not_ paths
  sandboxExes = { paths }:
    let
      wrapper = "${sandboxExeWrapper { inherit paths; }}/bin/sandbox-wrapper";
    in
    lib.runCommand "sandbox" { inherit paths; } ''
      export PATH=/usr/bin:/bin

      mkdir -p $out/bin

      for bit in $paths; do
        echo looking for executables in "$bit"

        for exe in $(find "$bit" -maxdepth 1 -perm +111 -not -type d); do
          exe=$(basename "$exe")
          echo found exe "$exe"

          ln -s "${wrapper}" $out/bin/$exe
        done
      done
    '';
}
