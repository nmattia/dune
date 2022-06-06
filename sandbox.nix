let
  lib = import ./lib.nix;
in
rec {


  mkProfile = { user, path }: ''
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

  sandboxExeWrapper = { user, path, paths, env /* list of "FOO=BAR" */ }: builtins.toFile "sandbox-wrapper" ''
    # TODO: why can't I set a shebang?
    set -euo pipefail
    echo starting exe $(basename $0)
    export PATH=${builtins.concatStringsSep ":" paths}:$PATH
    echo path exported
    ${ builtins.concatStringsSep "\n" (map (kv: "export ${kv}") env)}
    echo let us go
    profile=${builtins.toFile "profile.sb" (mkProfile {inherit user path;})}
    echo profile:
    cat $profile
    /usr/bin/sandbox-exec -f $profile $(basename $0) "$@"
  '';

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
