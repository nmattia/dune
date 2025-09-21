{ system }: {

  runCommand = name: env: cmd: builtins.derivation
    (
      rec {
        inherit name;
        builder = "/bin/bash";
        args = [ "-euo" "pipefail" "-c" cmd ];
        inherit system;
      } // env
    );


  writeScriptBin = name: text: builtins.derivation
    (
      rec {
        inherit name;

        inherit text;
        passAsFile = [ "text" ];

        builder = "/bin/bash";
        args = [
          "-euo"
          "pipefail"
          "-c"
          ''
            export PATH=/usr/sbin:/usr/bin:/bin:/usr/sbin

            mkdir -p $out/bin

            cat "$textPath" > "$out/bin/${name}"
            chmod +x "$out/bin/${name}"

          ''
        ];
        inherit system;
      }
    );


}
