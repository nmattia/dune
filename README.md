# Dune


``` bash
# .envrc

PATH_add "$(nix-build --no-link \
    https://github.com/nmattia/dune/archive/master.tar.gz \
    --argstr user "$USER" --argstr path "$PWD" \
    --arg packages '[ "nodejs" ]' \
    --arg env '[ "HOME='"$PWD"'"  "npm_config_cache='"$PWD"'/.npm" ]' \
    )/bin"
```
