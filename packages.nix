{
  nodejs =
    let
      npm-src = builtins.fetchTarball https://nodejs.org/download/release/v16.14.0/node-v16.14.0-darwin-x64.tar.gz;
    in
    { bin = "${npm-src}/bin"; };

}
