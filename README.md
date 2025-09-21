# Dune

``` bash
# .envrc
PATH_add "$(nix build github:nmattia/dune#shell --print-out-paths --no-link)/bin"

export DUNE_ROOT="$PWD"
export DUNE_ENV_HOME="$PWD/.home"
export DUNE_ENV_npm_config_cache="$PWD/.npm"
```

```
# .dune/flake.nix
{
  inputs.dune.url = github:nmattia/dune;
  outputs = { self, dune }: {
    packages.aarch64-darwin.shell = dune.lib.aarch64-darwin.shellWithPackages { packageNames = [ "python" "nodejs" ]; };
  };
}
```
