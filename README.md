# Dune


Sandboxed devenvs (for macOS)

Example:

```bash
$ nix build github:nmattia/dune#shell
$ ./result/bin/python3 # example shell includes python3
>>> import os
>>> os.listdir(".")
['result']
>>> os.listdir(os.getenv("HOME"))
Traceback (most recent call last):
  File "<python-input-2>", line 1, in <module>
    os.listdir(os.getenv("HOME"))
    ~~~~~~~~~~^^^^^^^^^^^^^^^^^^^
```

Use in a project:


``` bash
# .envrc for direnv
PATH_add "$(nix build .dune#shell --print-out-paths --no-link)/bin"

# set the sandbox boundary
export DUNE_ROOT="$PWD"

# set some environment variables in the sandbox
export DUNE_ENV_HOME="$PWD/.home"
export DUNE_ENV_npm_config_cache="$PWD/.npm"
```

```nix
# .dune/flake.nix
{
  inputs.dune.url = "github:nmattia/dune";
  outputs = { dune, ... }: {
    packages.aarch64-darwin.shell = dune.lib.aarch64-darwin.shellWithPackages { packageNames = [ "python" "nodejs" ]; };
  };
}
```
