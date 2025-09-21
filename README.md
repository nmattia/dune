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

Set up in a project:

```bash
git init .dune
cat << 'EOF' > .dune/flake.nix
# .dune/flake.nix
{
  inputs.dune.url = "github:nmattia/dune";
  outputs = { dune, ... }: {
    packages.aarch64-darwin.shell = dune.lib.aarch64-darwin.shellWithPackages { packageNames = [ "rustc" "cargo" ]; };
  };
}
EOF

git -C .dune add flake.nix
nix flake lock .dune

cat << 'EOF' > .dune/.envrc
# .envrc for direnv
PATH_add "$(nix build .dune#shell --print-out-paths --no-link)/bin"

# set the sandbox boundary
export DUNE_ROOT="$PWD"

# set some env vars in the sandbox
export DUNE_ENV_HOME="$PWD/.home" # create a fake home to avoid global littering

# more regular direnv env vars if necessary
export RUSTC_BOOTSTRAP=1
EOF

ln -s .dune/.envrc .envrc

# hide .dune dir from git
echo '.dune' >> .git/info/exclude
```
