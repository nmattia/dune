{

  runCommand = name: env: cmd: builtins.derivation
    (
      rec {
        inherit name;
        builder = /bin/bash;
        args = [ "-euo" "pipefail" "-c" input ];
        system = builtins.currentSystem;
        input = cmd;
      } // env
    );

}
