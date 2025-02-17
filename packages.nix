let
  lib = import ./lib.nix;
  rustToolchain =

    let

      rustc-version = "1.82.0";
      rustc-release-date = "2024-10-17";
      rust-toolchain-src = builtins.fetchurl {
        url = "https://static.rust-lang.org/dist/rust-${rustc-version}-x86_64-apple-darwin.pkg";
        sha256 = sha256:0z2nv787h0zys26643bbgf44farcyxnjb64ab6vgg2rywl5bdv97;
      };

      # found in https://static.rust-lang.org/dist/channel-rust-stable.toml through
      # https://github.com/rust-lang/cargo/issues/9733
      rust-std-wasm32 = builtins.fetchTarball {
        url = "https://static.rust-lang.org/dist/${rustc-release-date}/rust-std-${rustc-version}-wasm32-unknown-unknown.tar.gz";
        sha256 = sha256:0ixlr5x5lx30cykjj21vwsl37w2bfpr203lrw4y846i96r9cm4h0;
      };
      rust-std-thumbv6m-none-eabi = builtins.fetchTarball {
        url = "https://static.rust-lang.org/dist/${rustc-release-date}/rust-std-${rustc-version}-thumbv6m-none-eabi.tar.gz";
        sha256 = sha256:00b6ihmpwr33brk8rwfpbxdl9rl9ald56zmvb0mqqq7jhs4m8dlh;
      };
      rust-std-thumbv7em-none-eabihf = builtins.fetchTarball {
        url = "https://static.rust-lang.org/dist/${rustc-release-date}/rust-std-${rustc-version}-thumbv7em-none-eabihf.tar.gz";
        sha256 = sha256:1sa7xj6k34knhcjzprg0x40abjdhwm0hw5jbq543sr54lw37hf1w;
      };

    in
    lib.runCommand "rust" { } ''
      export PATH=/usr/sbin:/usr/bin:/bin:/usr/sbin
      pkgutil --expand ${rust-toolchain-src} $out
      cp -r $out/rust-std.pkg/Scripts/rust-std-x86_64-apple-darwin/lib/rustlib/x86_64-apple-darwin/lib $out/rustc.pkg/Scripts/rustc/lib/rustlib/x86_64-apple-darwin/
      cp -r ${rust-std-wasm32}/rust-std-wasm32-unknown-unknown/lib/rustlib/wasm32-unknown-unknown $out/rustc.pkg/Scripts/rustc/lib/rustlib/
      cp -r ${rust-std-thumbv6m-none-eabi}/rust-std-thumbv6m-none-eabi/lib/rustlib/thumbv6m-none-eabi $out/rustc.pkg/Scripts/rustc/lib/rustlib/
      cp -r ${rust-std-thumbv7em-none-eabihf}/rust-std-thumbv7em-none-eabihf/lib/rustlib/thumbv7em-none-eabihf $out/rustc.pkg/Scripts/rustc/lib/rustlib/

      mv $out/rustc.pkg/Scripts/rustc/bin/rustc $out/rustc.pkg/Scripts/rustc/bin/.rustc

      cat > $out/rustc.pkg/Scripts/rustc/bin/rustc <<EOF
      #!/usr/bin/env bash
      $out/rustc.pkg/Scripts/rustc/bin/.rustc "\$@"
      EOF
      chmod +x $out/rustc.pkg/Scripts/rustc/bin/rustc
    '';
in
rec
{
  nodejs =
    let
      npm-src = builtins.fetchTarball {
        url = https://nodejs.org/download/release/v20.9.0/node-v20.9.0-darwin-x64.tar.gz;
        sha256 = sha256:17vsjl91qj1p6y9gyigmcmhxd6lixsa6673rfh7m7knby6rzcdax;
      };
    in
    { bin = "${npm-src}/bin"; };

  cmake =
    let
      tarball = builtins.fetchTarball {
        url = https://github.com/Kitware/CMake/releases/download/v3.25.1/cmake-3.25.1-macos-universal.tar.gz;
        sha256 = sha256:16652qb4zqyc611yfh6w8spb9852rq5hdrd0m7dg3nlll1g8glpl;
      };
    in
    { bin = "${tarball}/CMake.app/Contents/bin"; };

  kubectl =
    let
      kubectl-src = builtins.fetchTarball {
        url = https://dl.k8s.io/v1.30.1/kubernetes-client-darwin-amd64.tar.gz;
        sha256 = sha256:1wy6kn3xhii3rvhhjnzdpm6fzjclibc37g4czr89nj0bnlj9xzyh;
      };
    in
    { bin = "${kubectl-src}/kubernetes/client/bin"; };

  krew =
    let
      version = "darwin_amd64";
      krew-src = builtins.fetchurl {
        url = "https://github.com/kubernetes-sigs/krew/releases/latest/download/krew-${version}.tar.gz";
        sha256 = sha256:06qymxnnx90zmnd0hm4h70ps6xlfb75zfb11i08wz1wahqs2ykaz;
      };
    in
    {
      bin = lib.runCommand "krew" { } ''
        export PATH=/usr/sbin:/usr/bin:/bin:/usr/sbin
        mkdir -p $out/
        cp ${krew-src} ./krew-${version}.tar.gz
        tar -xvzf ./krew-${version}.tar.gz
        cp ./krew-${version} $out/krew-${version}
        chmod +x $out/krew-${version}
      '';
    };

  yq =
    let
      yq-version = "4.44.1";
      yq-src = builtins.fetchurl {
        url = "https://github.com/mikefarah/yq/releases/download/v${yq-version}/yq_darwin_amd64.tar.gz";
        sha256 = sha256:1asfngvb2mn072yaafcgnabinm0s836lww7zryzpx6m9fzyih55r;
      };
    in
    {
      bin = lib.runCommand "yq" { } ''
        export PATH=/usr/sbin:/usr/bin:/bin:/usr/sbin
        cp ${yq-src} ./yq-v${yq-version}.tar.gz
        tar -xvzf ./yq-v${yq-version}.tar.gz
        mkdir -p $out
        cp yq_darwin_amd64 $out/yq
      '';
    };

  ffmpeg =
    let
      ffmpegZip = builtins.fetchurl {
        url = https://evermeet.cx/ffmpeg/ffmpeg-5.0.1.zip;
        sha256 = sha256:0v64z61gr579ij8kb0bwgcxz6yv86zna36fzqwrirzx8szsm1a3b;
      };
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
      rustfmt-src = builtins.fetchTarball {
        url = https://github.com/rust-lang/rustfmt/releases/download/v1.5.1/rustfmt_macos-x86_64_v1.5.1.tar.gz;
        sha256 = sha256:0403dfnxkh1py72a5hb86xdq3npij6i1v6gjwff4cwah2zlpnhw6;
      };
    in
    { bin = "${rustfmt-src}"; };

  wasm-pack =
    let
      wasm-pack-src = builtins.fetchTarball {
        url = https://github.com/rustwasm/wasm-pack/releases/download/v0.10.3/wasm-pack-v0.10.3-x86_64-apple-darwin.tar.gz;
        sha256 = sha256:1pzq0aws43m2phgwkp1i9wrscgijynvnrs0hbvhijmv5rfawd6lp;
      };
    in
    { bin = "${wasm-pack-src}"; };

  texinfo =
    let
      src = builtins.fetchTarball {
        url = https://ftp.gnu.org/gnu/texinfo/texinfo-7.0.1.tar.xz;
        sha256 = sha256:10h2w69kl93hi6f1h7b2xkjskyj1mzji6f2apf3bnsfv9hj4x650;
      };
    in

    {
      bin = lib.runCommand "texinfo" { } ''
        export PATH=/usr/sbin:/usr/bin:/bin:/usr/sbin

        ${src}/configure \
          --prefix=$out \
          \
          --disable-dependency-tracking \
          --disable-install-warnings \
          --disable-nls

        make
        make install
      '';
    }
  ;

  go =
    let
      platform = { aarch64-darwin = "darwin-arm64"; x86_64-darwin = "darwin-amd64"; }.${builtins.currentSystem};
      sha256 = { aarch64-darwin = sha256:0pgw4y9q9wjv3z8cr0c71a8301qvwqcwb1z4i7jaml4wagckvmvd; x86_64-darwin = sha256:136n87wa7xhb5x52xh8v8360h2x9vivzcdh5s5nis85dx3a4qwmd; }.${builtins.currentSystem};
      src = builtins.fetchTarball {
        url = "https://go.dev/dl/go1.22.1.${platform}.tar.gz";
        inherit sha256;
      };
    in
    {
      bin = "${src}/bin";
    };

  golangci-lint =
    let
      version = "1.57.2";
      platform = { aarch64-darwin = "darwin-arm64"; x86_64-darwin = "darwin-amd64"; }.${builtins.currentSystem};
      sha256 = { aarch64-darwin = sha256:1xv3i70qmsd8wmd3bs2ij18vff0vbn52fr77ksam9hxbql8sdjzv; x86_64-darwin = sha256:0n3zxs233ll7pyykldx3srsnv3nbgvlza3dklkfgrlmb1syzhcqi; }.${builtins.currentSystem};
      src = builtins.fetchTarball {
        url = "https://github.com/golangci/golangci-lint/releases/download/v${version}/golangci-lint-${version}-${platform}.tar.gz";

        inherit sha256;
      };
    in
    {
      bin = src;
    };

  terraform =
    let
      version = "1.8.4";
      platform = { aarch64-darwin = "darwin_arm64"; x86_64-darwin = "darwin_amd64"; }.${builtins.currentSystem};
      sha256 = { aarch64-darwin = sha256:16pl7hixy26ffyg08sc1xrgfdi3ckrpgr8bpc2zgwi425j3d4m3a; x86_64-darwin = sha256:0if4xqn48dh2ld61w4qw7a4h5kf4y16d6yha5l02jy370wmqfs2r; }.${builtins.currentSystem};
      src = builtins.fetchurl {
        url = "https://releases.hashicorp.com/terraform/${version}/terraform_${version}_${platform}.zip";
        inherit sha256;
      };
    in
    {
      bin = lib.runCommand "terraform" { } ''
        export PATH=/usr/sbin:/usr/bin:/bin:/usr/sbin

        mkdir -p $out
        cd $out
        unzip ${src}
      '';
    };

  ic-wasm =
    let
      ic-wasm-src = builtins.fetchurl {
        url = https://github.com/dfinity/ic-wasm/releases/download/0.3.5/ic-wasm-macos;
        sha256 = sha256:14n91hrm3jdbccbmz322qcx7fqg5wxs1m9j86wp9576fiy5pjfw4;
      };
    in
    {
      bin = lib.runCommand "ic-wasm" { } ''
        export PATH=/usr/sbin:/usr/bin:/bin:/usr/sbin
        mkdir -p $out/
        cp ${ic-wasm-src} $out/ic-wasm
        chmod +x $out/ic-wasm
      '';
    };

  bazelisk =
    let
      bazelisk-src = builtins.fetchurl {
        url = https://github.com/bazelbuild/bazelisk/releases/download/v1.20.0/bazelisk-darwin-amd64;
        sha256 = sha256:1gs5fml4nl4arzykwnwhffwnbwk4ip8wmspwz5nnak3ha66j59ji;
      };
    in
    {
      bin = lib.runCommand "bazelisk" { } ''
        export PATH=/usr/sbin:/usr/bin:/bin:/usr/sbin
        mkdir -p $out
        cp ${bazelisk-src} $out/bazel
        chmod +x $out/bazel
      '';
    };

  didc =
    let
      didc-release = "2024-02-27";
      didc-src = builtins.fetchurl {
        url = "https://github.com/dfinity/candid/releases/download/${didc-release}/didc-macos";
        sha256 = sha256:1x6xy5w08dhazsrdrwzkxx6lwf4klcl1l847j1yygl0v0dqyqwl1;
      };
    in
    {
      bin = lib.runCommand "didc" { } ''
        export PATH=/usr/sbin:/usr/bin:/bin:/usr/sbin
        mkdir -p $out
        cp ${didc-src} $out/didc
        chmod +x $out/didc
      '';
    };

  dfx =
    let

      dfx-version = "0.21.0";
      dfx-src = builtins.fetchurl {
        url = "https://github.com/dfinity/sdk/releases/download/${dfx-version}/dfx-${dfx-version}-x86_64-darwin.tar.gz";
        sha256 = sha256:1l8bmrwsv9vlbm3kh9v0sp0qv63ijhhpdj35y0w16p2bh7yij0w3;
      };
    in
    {
      bin = lib.runCommand "dfx" { } ''
        export PATH=/usr/sbin:/usr/bin:/bin:/usr/sbin
        cp ${dfx-src} ./out.tar.gz
        tar -xvzf ./out.tar.gz
        mkdir -p $out
        cp dfx $out/dfx
      '';
    };

  nsc =
    let
      platform = { aarch64-darwin = { os = "darwin"; arch = "arm64"; }; x86_64-darwin = { os = "darwin"; arch = "amd64"; }; }.${builtins.currentSystem};
      sha256 = { aarch64-darwin = sha256:14awdixrfbjrskfcrwkv7fjpcnpd4mmhgyydwmq6y8ndnjdsmyp7; x86_64-darwin = sha256:0wxnfjp1zwrrr28kx3khibc72gzqf9jfl6y2zxiz647s2mzmskyb; }.${builtins.currentSystem};
      version = "0.0.402";
      nsc-src = builtins.fetchurl { url = "https://get.namespace.so/packages/nsc/v${version}/nsc_${version}_${platform.os}_${platform.arch}.tar.gz"; name = "nsc.tar.gz";  inherit sha256; };
    in
    {
      bin = lib.runCommand "dfx" { } ''
        export PATH=/usr/sbin:/usr/bin:/bin:/usr/sbin
        cp ${nsc-src} ./out.tar.gz
        tar -xvzf ./out.tar.gz
        mkdir -p $out
        cp nsc $out/nsc
      '';
    };
}
