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
      export PATH=/usr/sbin:/usr/bin:/bin:/usr/sbin
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
rec
{
  nodejs =
    let
      npm-src = builtins.fetchTarball https://nodejs.org/download/release/v16.14.0/node-v16.14.0-darwin-x64.tar.gz;
    in
    { bin = "${npm-src}/bin"; };

  cmake =
    let
      tarball = builtins.fetchTarball https://github.com/Kitware/CMake/releases/download/v3.25.1/cmake-3.25.1-macos-universal.tar.gz;
    in
    { bin = "${tarball}/CMake.app/Contents/bin"; };


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

}
