let
  lib = import ./lib.nix;
  packages = import ./packages.nix;
  pkgs = import <nixpkgs> { };
in
rec {


  mkProfile = { user, path }: pkgs.writeText "profile.sb" ''
    (version 1)
    (allow default)
    (allow network*)
    (deny file* (subpath "/Users/${user}"))
    (allow file-read-metadata (subpath "/Users/${user}"))
    (allow file* (subpath "${path}"))
    (deny file* (subpath "/Applications"))
    (deny file* (subpath "/Users/${user}/Applications"))
    (allow file* (subpath "/Users/${user}/Library/Application Support"))
  '';


  sandboxExeWrapper = { user, path, paths, env /* list of "FOO=BAR" */ }: pkgs.writeText "sandbox-wrapper" ''
    # TODO: why can't I set a shebang?
    set -euo pipefail
    export PATH=${builtins.concatStringsSep ":" paths}:$PATH
    ${ builtins.concatStringsSep "\n" (map (kv: "export ${kv}") env)}
    profile=${mkProfile {inherit user path;}}
    exe=$(which $(basename "$0"))
    /usr/bin/sandbox-exec -f "$profile" "$exe" "$@"
  '';

  # note: if called directly, 'paths' should be strings for things like /bin, _not_ paths
  sandboxExes = { user, path, paths, env }: lib.runCommand "sandbox" { inherit paths; } ''
    export PATH=/usr/bin:/bin

    mkdir -p $out/bin

    for bit in $paths; do
      echo looking for executables in "$bit"

      for exe in "$bit"/*; do
        exe=$(basename "$exe")
        echo found exe "$exe"

        echo 'echo hello from exe' > $out/bin/$exe

        cat ${sandboxExeWrapper { inherit user path paths env; }} > $out/bin/$exe
        chmod +x "$out/bin/$exe"

        echo written "$out/bin/$exe"
      done
    done
  '';
}
