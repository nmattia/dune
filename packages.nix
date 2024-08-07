let
  lib = import ./lib.nix;
  rustToolchain =

    let

      rustc-version = "1.76.0";
      rustc-release-date = "2024-02-08";
      rust-toolchain-src = builtins.fetchurl "https://static.rust-lang.org/dist/rust-${rustc-version}-x86_64-apple-darwin.pkg";

      # found in https://static.rust-lang.org/dist/channel-rust-stable.toml through
      # https://github.com/rust-lang/cargo/issues/9733
      rust-std-wasm32 = builtins.fetchTarball "https://static.rust-lang.org/dist/${rustc-release-date}/rust-std-${rustc-version}-wasm32-unknown-unknown.tar.gz";
      rust-std-thumbv6m-none-eabi = builtins.fetchTarball "https://static.rust-lang.org/dist/${rustc-release-date}/rust-std-${rustc-version}-thumbv6m-none-eabi.tar.gz";
      rust-std-thumbv7em-none-eabihf = builtins.fetchTarball "https://static.rust-lang.org/dist/${rustc-release-date}/rust-std-${rustc-version}-thumbv7em-none-eabihf.tar.gz";

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
      npm-src = builtins.fetchTarball https://nodejs.org/download/release/v20.9.0/node-v20.9.0-darwin-x64.tar.gz;
    in
    { bin = "${npm-src}/bin"; };

  cmake =
    let
      tarball = builtins.fetchTarball https://github.com/Kitware/CMake/releases/download/v3.25.1/cmake-3.25.1-macos-universal.tar.gz;
    in
    { bin = "${tarball}/CMake.app/Contents/bin"; };

  kubectl =
    let
      kubectl-src = builtins.fetchTarball https://dl.k8s.io/v1.30.1/kubernetes-client-darwin-amd64.tar.gz;
    in
    { bin = "${kubectl-src}/kubernetes/client/bin"; };

  krew =
    let
      version = "darwin_amd64";
      krew-src = builtins.fetchurl "https://github.com/kubernetes-sigs/krew/releases/latest/download/krew-${version}.tar.gz";
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
      yq-src = builtins.fetchurl "https://github.com/mikefarah/yq/releases/download/v${yq-version}/yq_darwin_amd64.tar.gz";
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

  pkg-config =
    let
      src = builtins.fetchTarball https://pkgconfig.freedesktop.org/releases/pkg-config-0.29.2.tar.gz;
    in

    {
      bin = lib.runCommand "pkg-config" { } ''
        export PATH=/usr/sbin:/usr/bin:/bin:/usr/sbin

        ${src}/configure \
          --prefix=$out \
          --with-internal-glib \
          --build=aarch64-apple-darwin13

        make
        make install
      '';
    }
  ;

  m4 =
    let
      src = builtins.fetchTarball http://ftp.gnu.org/gnu/m4/m4-1.4.19.tar.gz;
    in

    {
      bin = lib.runCommand "m4" { } ''
        export PATH=/usr/sbin:/usr/bin:/bin:/usr/sbin

        ${src}/configure \
          --prefix=$out \
          --with-internal-glib \
          --build=aarch64-apple-darwin13

        make
        make install

        # TODO: find a better solution for files written in $out/bin
        mv $out/bin/m4 $out/m4
      '';
    }
  ;

  texinfo =
    let
      src = builtins.fetchTarball https://ftp.gnu.org/gnu/texinfo/texinfo-7.0.1.tar.xz;
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

  gmp =
    let
      src = builtins.fetchTarball https://ftp.gnu.org/gnu/gmp/gmp-6.2.1.tar.xz;
    in

    {
      lib = lib.runCommand "gmp" { } ''
        export PATH=/usr/sbin:/usr/bin:/bin:/usr/sbin

        ${src}/configure \
          --prefix=$out \
          --build=aarch64-apple-darwin13 \
          --with-pic

        make
        make install
      '';
    }
  ;

  isl =
    let
      src = builtins.fetchTarball https://libisl.sourceforge.io/isl-0.25.tar.xz;
    in
    {
      lib = lib.runCommand "isl" { } ''
        export PATH=/usr/sbin:/usr/bin:/bin:/usr/sbin:${pkg-config.bin}/bin
        export PKG_CONFIG_PATH=${gmp.lib}/lib/pkgconfig

        ${src}/configure \
          CFLAGS=$(pkg-config --cflags-only-I gmp) \
          LDFLAGS=$(pkg-config --libs-only-L gmp) \
          --prefix=$out \
          --build=aarch64-apple-darwin13 \
          --with-pic

        make
        make install
      '';


    };

  mpfr =
    let
      src = builtins.fetchTarball https://ftp.gnu.org/gnu/mpfr/mpfr-4.1.0.tar.xz;
    in
    {
      lib = lib.runCommand "mpfr" { } ''
        export PATH=/usr/sbin:/usr/bin:/bin:/usr/sbin:${pkg-config.bin}/bin
        export PKG_CONFIG_PATH=${gmp.lib}/lib/pkgconfig

        ${src}/configure \
          CFLAGS="$(pkg-config --cflags-only-I gmp)" \
          LDFLAGS="$(pkg-config --libs-only-L gmp)" \
          --prefix=$out \
          --build=aarch64-apple-darwin13 \
          --with-pic

        make
        make install
      '';
    };

  libmpc =
    let
      src = builtins.fetchTarball https://ftp.gnu.org/gnu/mpc/mpc-1.3.1.tar.gz;
    in
    {
      lib = lib.runCommand "libmpc" { } ''
        export PATH=/usr/sbin:/usr/bin:/bin:/usr/sbin:${pkg-config.bin}/bin
        export PKG_CONFIG_PATH=${gmp.lib}/lib/pkgconfig:${mpfr.lib}/lib/pkgconfig

        ${src}/configure \
          CFLAGS="$(pkg-config --cflags-only-I gmp mpfr)" \
          LDFLAGS="$(pkg-config --libs-only-L gmp mpfr)" \
          --prefix=$out \
          --build=aarch64-apple-darwin13 \
          --with-pic

        make
        make install
      '';
    };

  gcc =
    let
      src = builtins.fetchTarball https://ftp.gnu.org/gnu/gcc/gcc-12.2.0/gcc-12.2.0.tar.xz;
      src-patched = lib.runCommand "gcc-src-patched" { } ''
        export PATH=/usr/sbin:/usr/bin:/bin:/usr/sbin
        cp -r ${src}/. $out
        chmod -R +w $out
        cd $out
        patch <${patch}
      '';
      patch = builtins.fetchurl https://raw.githubusercontent.com/Homebrew/formula-patches/1d184289/gcc/gcc-12.2.0-arm.diff;
    in
    {
      bin =
        lib.runCommand "gcc" { } ''
          export PATH=/usr/sbin:/usr/bin:/bin:/usr/sbin
          export AR=ar

          ${src-patched}/configure \
            --with-gmp=${gmp.lib} \
            --with-mpfr=${mpfr.lib} \
            --with-mpc=${libmpc.lib} \
            --with-gcc-major-version-only \
            --disable-nls \
            --build=aarch64-apple-darwin13 \
            --enable-languages=c \
            --with-sysroot=/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk \
            --prefix=$out

          make
          make install
        '';
    };

  gcc-arm-none-eabi =
    let
      pkg = builtins.fetchurl https://developer.arm.com/-/media/Files/downloads/gnu/12.2.rel1/binrel/arm-gnu-toolchain-12.2.rel1-darwin-x86_64-arm-none-eabi.pkg;
      extracted =
        lib.runCommand "gcc-arm-none-eabi" { } ''
          export PATH=/usr/sbin:/usr/bin:/bin:/usr/sbin
          pkgutil --expand-full ${pkg} $out
        '';
    in
    {
      bin = "${extracted}/Payload/bin";
    };

  avr-binutils =
    let
      src = builtins.fetchTarball https://ftp.gnu.org/gnu/binutils/binutils-2.38.tar.xz;
      src-patched = lib.runCommand "gcc-src-patched" { } ''
        export PATH=/usr/sbin:/usr/bin:/bin:/usr/sbin
        cp -r ${src}/. $out
        chmod -R +w $out
        cd $out
        patch <${patch}
      '';
      patch = builtins.fetchurl https://raw.githubusercontent.com/osx-cross/homebrew-avr/18d50ba2a168a3b90a25c96e4bc4c053df77d7dc/Patch/avr-binutils-elf-bfd-gdb-fix.patch;
    in
    {
      bin =
        lib.runCommand "avr-binutils" { } ''
          export PATH=/usr/sbin:/usr/bin:/bin:/usr/sbin

          PATH=${texinfo.bin}/bin:$PATH

          ${src-patched}/configure \
            \
            --build=aarch64-apple-darwin13 \
            --target=avr \
            --prefix=$out \
            \
            --disable-nls \
            --disable-debug \
            --disable-werror \
            --disable-dependency-tracking \

          make
          make install
        '';
    };


  gcc-avr =
    let
      src = builtins.fetchTarball https://ftp.gnu.org/gnu/gcc/gcc-12.2.0/gcc-12.2.0.tar.xz;
      src-patched = lib.runCommand "gcc-src-patched" { } ''
        export PATH=/usr/sbin:/usr/bin:/bin:/usr/sbin
        cp -r ${src}/. $out
        chmod -R +w $out
        cd $out
        patch <${patch-avr-texi}
        patch <${patch-apple-silicon}
      '';

      patch-avr-texi = builtins.fetchurl https://gist.githubusercontent.com/nmattia/3f9b03705257e1e20bc9e4e5968e58ef/raw/924bb6fd6b355844e1893fa194fe08009635f7a3/gcc.patch;
      patch-apple-silicon = builtins.fetchurl https://raw.githubusercontent.com/Homebrew/formula-patches/1d184289/gcc/gcc-12.2.0-arm.diff;
    in
    {
      bin =
        lib.runCommand "gcc-avr" { } ''
          export PATH=/usr/sbin:/usr/bin:/bin:/usr/sbin

          # needed otherwise avr-ar isn't found
          PATH=${avr-binutils.bin}/bin:$PATH

          ${src-patched}/configure \
            --build=aarch64-apple-darwin13 \
            --target=avr \
            --prefix=$out \
            \
            --with-gcc-major-version-only \
            \
            --with-gmp=${gmp.lib} \
            --with-mpfr=${mpfr.lib} \
            --with-mpc=${libmpc.lib} \
            --with-ld=${avr-binutils.bin}/bin/avr-ld \
            --with-as=${avr-binutils.bin}/bin/avr-as \
            \
            --with-dwarf2 \
            --with-avrlibc \
            \
            --enable-languages=c \
            \
            --disable-nls \
            --disable-libssp \
            --disable-shared \
            --disable-threads \
            --disable-libgomp

          make BOOT_LDFLAGS=-Wl,-headerpad_max_install_names
          make install
        '';
    };



  avr-libc =
    let
      src = builtins.fetchTarball https://download.savannah.gnu.org/releases/avr-libc/avr-libc-2.1.0.tar.bz2;
    in
    {
      lib = lib.runCommand "avr-libc" { } ''
        export PATH=/usr/sbin:/usr/bin:/bin:/usr/sbin

        PATH=${gcc-avr.bin}/bin:$PATH
        PATH=${avr-binutils.bin}/bin:$PATH

        export ac_cv_build=aarch64-apple-darwin

        ${src}/configure \
          --prefix=$out \
          --host=avr

        make
        make install
      '';
    };


  go =
    let
      platform = { aarch64-darwin = "darwin-arm64"; x86_64-darwin = "darwin-amd64"; }.${builtins.currentSystem};
      src = builtins.fetchTarball "https://go.dev/dl/go1.22.1.${platform}.tar.gz";
    in
    {
      bin = "${src}/bin";
    };

  golangci-lint =
    let
      version = "1.57.2";
      platform = { aarch64-darwin = "darwin-arm64"; x86_64-darwin = "darwin-amd64"; }.${builtins.currentSystem};
      src = builtins.fetchTarball "https://github.com/golangci/golangci-lint/releases/download/v${version}/golangci-lint-${version}-${platform}.tar.gz";
    in
    {
      bin = src;
    };

  terraform =
    let
      version = "1.8.4";
      platform = { aarch64-darwin = "darwin_arm64"; x86_64-darwin = "darwin_amd64"; }.${builtins.currentSystem};
      src = builtins.fetchurl "https://releases.hashicorp.com/terraform/${version}/terraform_${version}_${platform}.zip";
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
      ic-wasm-src = builtins.fetchurl "https://github.com/dfinity/ic-wasm/releases/download/0.3.5/ic-wasm-macos";
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
      bazelisk-src = builtins.fetchurl "https://github.com/bazelbuild/bazelisk/releases/download/v1.20.0/bazelisk-darwin-amd64";
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
      didc-src = builtins.fetchurl "https://github.com/dfinity/candid/releases/download/${didc-release}/didc-macos";
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
      dfx-src = builtins.fetchurl "https://github.com/dfinity/sdk/releases/download/${dfx-version}/dfx-${dfx-version}-x86_64-darwin.tar.gz";
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
      version = "0.0.377";
      nsc-src = builtins.fetchurl { url = "https://get.namespace.so/packages/nsc/v${version}/nsc_${version}_${platform.os}_${platform.arch}.tar.gz"; name = "nsc.tar.gz"; };
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
