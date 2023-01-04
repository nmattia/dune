{

  runCommand = name: env: cmd: builtins.derivation
    (
      rec {
        inherit name;
        builder = "/bin/bash";
        args = [ "-euo" "pipefail" "-c" cmd ];
        system = builtins.currentSystem;
      } // env
    );

}
