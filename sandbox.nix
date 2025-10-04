{ lib }:
let
  packages = import ./packages.nix;
in
rec {

  sandboxExeWrapper = { paths, }: lib.writeScriptBin "sandbox-wrapper" ''
    #!/usr/bin/env bash

    set -euo pipefail

    DUNE_UNTRUSTED_PATH=${builtins.concatStringsSep ":" paths} \
        DUNE_EXE_NAME="$(basename "$0")" \
        DUNE_SANDBOX_DIR="$(dirname "$0")" \
        DUNE_SANDBOXER=${./sandboxer} \
        exec ${./dune-runner} "$@"
  '';

  # helper to run any command inside the (sandboxed) dune environment
  duneExec = lib.writeScriptBin "dune-exec" ''
    #!/usr/bin/env bash
    set -euo pipefail

    exec -a "$(basename "$0")" "$@"
  '';

  # note: if called directly, 'paths' should be strings for things like /bin, _not_ paths
  sandboxExes = { paths }:
    let
      paths_ = paths ++ [ "${duneExec}/bin" ];
      wrapper = "${sandboxExeWrapper { paths = paths_; }}/bin/sandbox-wrapper";
    in
    lib.runCommand "sandbox" { paths = paths_; } ''
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
