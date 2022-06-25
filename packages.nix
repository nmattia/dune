let lib = import ./lib.nix;
in
{
  nodejs =
    let
      npm-src = builtins.fetchTarball https://nodejs.org/download/release/v16.14.0/node-v16.14.0-darwin-x64.tar.gz;
    in
    { bin = "${npm-src}/bin"; };


    ffmpeg =
      let ffmpegZip = builtins.fetchurl https://evermeet.cx/ffmpeg/ffmpeg-5.0.1.zip;
      ffmpeg = lib.runCommand "ffmpeg" {}''
        export PATH=/usr/bin:/bin
        mkdir -p $out/bin
        unzip ${ffmpegZip} -d $out/bin
        '';
      in
      { bin = "${ffmpeg}/bin"; };
}
