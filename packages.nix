{ system }:
let
  lib = import ./lib.nix { inherit system; };
  sources = builtins.fromJSON (builtins.readFile ./nix/sources.json);
  rustToolchain =

    let
      platform = { aarch64-darwin = "aarch64-apple-darwin"; x86_64-darwin = "x86_64-apple-darwin"; }.${system};
      rust-toolchain = sources."rust-toolchain-${platform}";
      rustc-version = rust-toolchain.rustc-version;
      rustc-release-date = rust-toolchain.rustc-release-date;
      rust-toolchain-src = builtins.fetchurl {
        inherit (sources."rust-toolchain-${platform}") url sha256;
      };

      rust-src = builtins.fetchTarball {
        inherit (sources."rust-src") url sha256;
      };

      # found in https://static.rust-lang.org/dist/channel-rust-stable.toml through
      # https://github.com/rust-lang/cargo/issues/9733
      rust-std-wasm32 = builtins.fetchTarball {
        inherit (sources."rust-std-wasm32") url sha256;
      };
      rust-std-thumbv6m-none-eabi = builtins.fetchTarball {
        inherit (sources."rust-std-thumbv6m-none-eabi") url sha256;
      };
      rust-std-thumbv7em-none-eabihf = builtins.fetchTarball {
        inherit (sources."rust-std-thumbv7em-none-eabihf") url sha256;
      };

      # for ESP32-C3
      rust-std-riscv32imc-unknown-none-elf = builtins.fetchTarball {
        inherit (sources."rust-std-riscv32imc-unknown-none-elf") url sha256;
      };

      rustfmt = builtins.fetchTarball {
        inherit (sources."rustfmt-${platform}") url sha256;
      };

      clippy = builtins.fetchTarball {
        inherit (sources."clippy-${platform}") url sha256;
      };

    in
    lib.runCommand "rust" { } ''
      export PATH=/usr/sbin:/usr/bin:/bin:/usr/sbin
      pkgutil --expand ${rust-toolchain-src} $out
      cp -r $out/rust-std.pkg/Scripts/rust-std-${platform}/lib/rustlib/${platform}/lib $out/rustc.pkg/Scripts/rustc/lib/rustlib/${platform}/
      cp -r ${rust-std-wasm32}/rust-std-wasm32-unknown-unknown/lib/rustlib/wasm32-unknown-unknown $out/rustc.pkg/Scripts/rustc/lib/rustlib/
      cp -r ${rust-std-thumbv6m-none-eabi}/rust-std-thumbv6m-none-eabi/lib/rustlib/thumbv6m-none-eabi $out/rustc.pkg/Scripts/rustc/lib/rustlib/
      cp -r ${rust-std-thumbv7em-none-eabihf}/rust-std-thumbv7em-none-eabihf/lib/rustlib/thumbv7em-none-eabihf $out/rustc.pkg/Scripts/rustc/lib/rustlib/
      cp -r ${rust-std-riscv32imc-unknown-none-elf}/rust-std-riscv32imc-unknown-none-elf/lib/rustlib/riscv32imc-unknown-none-elf $out/rustc.pkg/Scripts/rustc/lib/rustlib/
      cp -r ${rustfmt}/rustfmt-preview/bin/. $out/rustc.pkg/Scripts/rustc/bin
      cp -r ${clippy}/clippy-preview/bin/. $out/rustc.pkg/Scripts/rustc/bin

      cp -r ${rust-src}/rust-src/lib/rustlib/src $out/rustc.pkg/Scripts/rustc/lib/rustlib/

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
      node-version = "v22.17.0";
      platform = { aarch64-darwin = "darwin-arm64"; x86_64-darwin = "darwin-x64"; }.${system};
      sha256 = { aarch64-darwin = sha256:00k7ypbw2si6yl5ilrcv4h39bf1kgmslfqmw32sspjgvlsa1qff2; x86_64-darwin = sha256:14my7k12gkkzivrl3mnvf72h7xfrhayziplzi59hhvwbwcvf18s2; }.${system};
      node-src = builtins.fetchTarball {
        url = "https://nodejs.org/download/release/${node-version}/node-${node-version}-${platform}.tar.gz";
        inherit sha256;
      };
    in
    { bin = "${node-src}/bin"; };

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
        url = "https://github.com/kubernetes-sigs/krew/releases/download/v0.4.4/krew-${version}.tar.gz";
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



  moc =
    let
      version = "0.16.1";
      platform = { x86_64-darwin = "Darwin-x86_64"; }.${system};
      sha256 = { x86_64-darwin = sha256:13c6p7icvb64f4c5xhi8id0x8kypj0gsj96mq5mlqnl1iilpcqss; }.${system};
      src = builtins.fetchurl {
        url = "https://github.com/dfinity/motoko/releases/download/${version}/motoko-${platform}-${version}.tar.gz";

        inherit sha256;
      };
    in
    {
      bin = lib.runCommand "moc" { } ''
        export PATH=/usr/sbin:/usr/bin:/bin:/usr/sbin
        cp ${src} ./moc-v${version}.tar.gz
        tar -xvzf ./moc-v${version}.tar.gz
        mkdir -p $out
        cp ./moc $out/
      '';
    };

  protoc =
    let
      version = "32.0";
      platform = { x86_64-darwin = "osx-x86_64"; }.${system};
      sha256 = { x86_64-darwin = sha256:1xmz74hxb46yxhgx4siy5h16kk265pxq3klb18dv2an1vlavmvk3; }.${system};
      protocZip = builtins.fetchurl {
        url = "https://github.com/protocolbuffers/protobuf/releases/download/v${version}/protoc-${version}-${platform}.zip";
        inherit sha256;
      };
      protoc = lib.runCommand "protoc" { } ''
        export PATH=/usr/bin:/bin
        mkdir -p $out/bin
        unzip ${protocZip} -d $out
      '';
    in
    { bin = "${protoc}/bin"; };

  yq =
    let
      version = "4.45.4";
      platform = { aarch64-darwin = "darwin_arm64"; x86_64-darwin = "darwin_amd64"; }.${system};
      sha256 = { aarch64-darwin = sha256:3f3424b21b0835bcffc444c15dccc2ca4bb8a765d2f8aeb7415cdb4b494081b1; x86_64-darwin = sha256:821bb7e491d2dae72c0c83d69f521dd0c8f473de35a50566fb3f718131f54747; }.${system};
      src = builtins.fetchurl {
        url = "https://github.com/mikefarah/yq/releases/download/v${version}/yq_${platform}.tar.gz";

        inherit sha256;
      };
    in
    {
      bin = lib.runCommand "yq" { } ''
        export PATH=/usr/sbin:/usr/bin:/bin:/usr/sbin
        cp ${src} ./yq-v${version}.tar.gz
        tar -xvzf ./yq-v${version}.tar.gz
        mkdir -p $out
        cp yq_${platform} $out/yq
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

  wasm-pack =
    let
      wasm-pack-src = builtins.fetchTarball {
        url = https://github.com/rustwasm/wasm-pack/releases/download/v0.10.3/wasm-pack-v0.10.3-x86_64-apple-darwin.tar.gz;
        sha256 = sha256:1pzq0aws43m2phgwkp1i9wrscgijynvnrs0hbvhijmv5rfawd6lp;
      };
    in
    { bin = "${wasm-pack-src}"; };

  # mostly used in python build
  openssl =
    let
      src = builtins.fetchTarball {
        url = https://github.com/openssl/openssl/releases/download/openssl-3.5.0/openssl-3.5.0.tar.gz;
        sha256 = sha256:1by6j3k4zrjqpr249w1x6403xv64djhcfnw9139mjwdv1nnny7dz;
      };

      toplevel = lib.runCommand "pysrc" { } ''
        export PATH=/usr/sbin:/usr/bin:/bin:/usr/sbin

        ${src}/configure \
          --prefix=$out

        make
        make install
      '';
    in

    {
      lib = toplevel;
    }
  ;

  # build from source because it's a real pain to relocate an install hardcoded for
  # /Library
  python =
    let
      src = builtins.fetchTarball {
        url = https://www.python.org/ftp/python/3.13.5/Python-3.13.5.tar.xz;
        sha256 = sha256:05bs46x8fq14cqgsr06hnbbflslmm90hrvfj9iwgcjdahsc8fn09;
      };

      toplevel = lib.runCommand "pysrc" { } ''
        export PATH=/usr/sbin:/usr/bin:/bin:/usr/sbin

        ${src}/configure \
            --with-openssl=${openssl.lib} \
          --prefix=$out

        make
        make install
      '';
    in
    {
      bin = "${toplevel}/bin";
    }
  ;

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
      platform = { aarch64-darwin = "darwin-arm64"; x86_64-darwin = "darwin-amd64"; }.${system};
      sha256 = { aarch64-darwin = sha256:0pgw4y9q9wjv3z8cr0c71a8301qvwqcwb1z4i7jaml4wagckvmvd; x86_64-darwin = sha256:136n87wa7xhb5x52xh8v8360h2x9vivzcdh5s5nis85dx3a4qwmd; }.${system};
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
      platform = { aarch64-darwin = "darwin-arm64"; x86_64-darwin = "darwin-amd64"; }.${system};
      sha256 = { aarch64-darwin = sha256:1xv3i70qmsd8wmd3bs2ij18vff0vbn52fr77ksam9hxbql8sdjzv; x86_64-darwin = sha256:0n3zxs233ll7pyykldx3srsnv3nbgvlza3dklkfgrlmb1syzhcqi; }.${system};
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
      platform = { aarch64-darwin = "darwin_arm64"; x86_64-darwin = "darwin_amd64"; }.${system};
      sha256 = { aarch64-darwin = sha256:16pl7hixy26ffyg08sc1xrgfdi3ckrpgr8bpc2zgwi425j3d4m3a; x86_64-darwin = sha256:0if4xqn48dh2ld61w4qw7a4h5kf4y16d6yha5l02jy370wmqfs2r; }.${system};
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
      platform = { aarch64-darwin = "darwin-arm64"; x86_64-darwin = "darwin-amd64"; }.${system};
      version = "1.20.0";
      url = "https://github.com/bazelbuild/bazelisk/releases/download/v${version}/bazelisk-${platform}";
      sha256 = { aarch64-darwin = sha256:19k75b03wdkms0yl7hnc3gw3xf50pdzj83i4zcqmkhyxq10k6x99; x86_64-darwin = sha256:1gs5fml4nl4arzykwnwhffwnbwk4ip8wmspwz5nnak3ha66j59ji; }.${system};
      bazelisk-src = builtins.fetchurl { inherit url sha256; };
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

      dfx-version = "0.28.0";
      dfx-src = builtins.fetchurl {
        url = "https://github.com/dfinity/sdk/releases/download/${dfx-version}/dfx-${dfx-version}-x86_64-darwin.tar.gz";
        sha256 = sha256:194kczxshflzsjfnw0chnrv48a3cffwhjcqmp89ysrxl47332gzr;
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
      platform = { aarch64-darwin = { os = "darwin"; arch = "arm64"; }; x86_64-darwin = { os = "darwin"; arch = "amd64"; }; }.${system};
      sha256 = { aarch64-darwin = sha256:1pkcmjfv7ryxz8xbdsp7y08c32qhjd1g0hya336403gfwnx550gz; x86_64-darwin = sha256:13hmwc2cl0aqfi7c8l2i2qn8zjffzrn5c44i2w8pfpdba1izca9i; }.${system};
      version = "0.0.412";
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
