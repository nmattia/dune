let
  lib = import ./lib.nix;
  rustToolchain =

    let

      rustc-version = "1.63.0";
      rustc-release-date = "2022-08-11";
      rust-toolchain-src = builtins.fetchurl "https://static.rust-lang.org/dist/rust-${rustc-version}-x86_64-apple-darwin.pkg";

      # found in https://static.rust-lang.org/dist/channel-rust-stable.toml through
      # https://github.com/rust-lang/cargo/issues/9733
      rust-std-wasm32 = builtins.fetchTarball "https://static.rust-lang.org/dist/${rustc-release-date}/rust-std-${rustc-version}-wasm32-unknown-unknown.tar.gz";

    in
    lib.runCommand "rust" { } ''
      export PATH=/usr/sbin:/usr/bin:/bin:
      pkgutil --expand ${rust-toolchain-src} $out
      cp -r $out/rust-std.pkg/Scripts/rust-std-x86_64-apple-darwin/lib/rustlib/x86_64-apple-darwin/lib $out/rustc.pkg/Scripts/rustc/lib/rustlib/x86_64-apple-darwin/
      cp -r ${rust-std-wasm32}/rust-std-wasm32-unknown-unknown/lib/rustlib/wasm32-unknown-unknown $out/rustc.pkg/Scripts/rustc/lib/rustlib/

      mv $out/rustc.pkg/Scripts/rustc/bin/rustc $out/rustc.pkg/Scripts/rustc/bin/.rustc

      cat > $out/rustc.pkg/Scripts/rustc/bin/rustc <<EOF
      #!/usr/bin/env bash
      $out/rustc.pkg/Scripts/rustc/bin/.rustc "\$@"
      EOF
      chmod +x $out/rustc.pkg/Scripts/rustc/bin/rustc
    '';
in
{
  nodejs =
    let
      npm-src = builtins.fetchTarball https://nodejs.org/download/release/v16.14.0/node-v16.14.0-darwin-x64.tar.gz;
    in
    { bin = "${npm-src}/bin"; };


  ffmpeg =
    let
      ffmpegZip = builtins.fetchurl https://evermeet.cx/ffmpeg/ffmpeg-5.0.1.zip;
      ffmpeg = lib.runCommand "ffmpeg" { } ''
        export PATH=/usr/bin:/bin
        mkdir -p $out/bin
        unzip ${ffmpegZip} -d $out/bin
      '';
    in
    { bin = "${ffmpeg}/bin"; };


  rustc = { bin = "${rustToolchain}/rustc.pkg/Scripts/rustc/bin"; };
  cargo = { bin = "${rustToolchain}/cargo.pkg/Scripts/cargo/bin"; };

  rustfmt =
    let
      rustfmt-src = builtins.fetchTarball https://github.com/rust-lang/rustfmt/releases/download/v1.5.1/rustfmt_macos-x86_64_v1.5.1.tar.gz;
    in
    { bin = "${rustfmt-src}"; };

  wasm-pack =
    let wasm-pack-src = builtins.fetchTarball https://github.com/rustwasm/wasm-pack/releases/download/v0.10.3/wasm-pack-v0.10.3-x86_64-apple-darwin.tar.gz;
    in
    { bin = "${wasm-pack-src}"; };

}
