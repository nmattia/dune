# Dune


``` bash
# .envrc

PATH_add "$(nix-build --no-link \
    https://github.com/nmattia/dune/archive/master.tar.gz \
    --argstr user "$USER" --argstr path "$PATH" \
    --arg packages '[ "nodejs" ]')/bin"
```
