let
  lib = import ./lib.nix;
  packages = import ./packages.nix;
  pkgs = import <nixpkgs> { };
in
rec {

  sandboxExeWrapper = { paths, }: pkgs.writeScriptBin "sandbox-wrapper" ''
    #!/usr/bin/env bash

    set -euo pipefail

    # DUNE_ROOT: the sandbox root. Anything higher up will be denied access.
    dune_root="''${DUNE_ROOT:?No DUNE_ROOT}"
    unset DUNE_ROOT

    # DUNE_RAW_PATH: colon-separated list of directories to sandbox
    DUNE_RAW_PATH=${builtins.concatStringsSep ":" paths}
    dune_raw_path="''${DUNE_RAW_PATH:?No DUNE_RAW_PATH}"
    unset DUNE_RAW_PATH

    # remove the sandbox path from the PATH so that
    # executables can call the un-sandboxed exes (top-level is still
    # sandboxed). Nested sandboxing is an error.
    here="$(dirname "$0")"
    PATH="''${PATH#$here:?}" # remove "$here" from "$PATH"

    exe_name="$(basename "$0")"
    exe="$(PATH="$dune_raw_path" command -v "$exe_name")"

    # DUNE_ENV_FOO: environment to set in the sandbox
    # Read NUL-delimited env vars: DUNE_ENV_FOO=hello, world!
    while IFS= read -r -d ''' rec; do
        [[ $rec == DUNE_ENV_*=* ]] || continue

        name_full=''${rec%%=*}          # "DUNE_ENV_FOO"
        val=''${rec#*=}                 # "hello, world!"
        name=''${name_full#DUNE_ENV_}   # "FOO"

        unset "$name_full"

        export "$name=$val"
    done < <(env -0)

    # make unsandboxed bins available
    PATH="$dune_raw_path:$PATH"

    exec ${./sandboxer} --root "$dune_root" --home "$HOME" -- "$exe" "$@"
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
