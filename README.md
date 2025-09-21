# Dune


``` bash
# .envrc

PATH_add "$(nix-build --no-link \
    https://github.com/nmattia/dune/archive/master.tar.gz \
    --arg packages '[ "python" "nodejs" ]' \
    )/bin"

export DUNE_ROOT="$PWD"
export DUNE_ENV_HOME="$PWD/.home"
export DUNE_ENV_npm_config_cache="$PWD/.npm"
```
