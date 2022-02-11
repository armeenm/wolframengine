{ lib
, stdenv
, autoPatchelfHook
, buildEnv
, makeWrapper
, requireFile
, alsa-lib
, cups
, dbus
, flite
, fontconfig
, freetype
, gcc-unwrapped
, glib
, gmpxx
, keyutils
, libGL
, libGLU
, libpcap
, libtins
, libuuid
, libxkbcommon
, libxml2
, llvmPackages_12
, matio
, mpfr
, ncurses
, opencv4
, openjdk11
, openssl
, pciutils
, tre
, unixODBC
, xkeyboard_config
, xorg
, zlib
, installerFile ? "WolframEngine_13.0.0_LINUX.sh"
, installerSha256 ? ""
}:

stdenv.mkDerivation rec {
  name = "wolframengine";
  version = "13.0.0";

  src = requireFile {
    name = installerFile;
    sha256 = installerSha256;
    message = "nix store add-file ${installerFile}";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
  ];

  buildInputs = [
    alsa-lib
    cups.lib
    dbus
    flite
    fontconfig
    freetype
    glib
    gmpxx
    keyutils.lib
    libGL
    libGLU
    libpcap
    libtins
    libuuid
    libxkbcommon
    libxml2
    llvmPackages_12.libllvm.lib
    matio
    mpfr
    ncurses
    opencv4
    openjdk11
    openssl
    pciutils
    tre
    unixODBC
    xkeyboard_config
  ] ++ (with xorg; [
    libICE
    libSM
    libX11
    libXScrnSaver
    libXcomposite
    libXcursor
    libXdamage
    libXext
    libXfixes
    libXi
    libXinerama
    libXmu
    libXrandr
    libXrender
    libXtst
    libxcb
  ]);

  dontConfigure = true;
  dontBuild = true;

  unpackPhase = ''
    runHook preUnpack

    offset=$(${stdenv.shell} -c "$(grep -axm1 -e 'offset=.*' $src); echo \$offset" $src)
    tail -c +$(($offset + 1)) $src | tar -xf -

    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    cd "$TMPDIR/Unix/Installer"

    mkdir -p "$out/lib/udev/rules.d"
fail
    # Remove PATH restriction, root and avahi daemon checks, and hostname call
    sed -i '
      s/^PATH=/# &/
      s/InstallAsRoot$/isRoot=true/
      s/^checkAvahiDaemon$/# &/
      s/^checkSELinux_$/# &/
      s/`hostname`/""/
    ' MathInstaller

    patchShebangs MathInstaller
    substituteInPlace MathInstaller \
      --replace /etc/udev/rules.d $out/lib/udev/rules.d

    XDG_DATA_HOME="$out/share" HOME="$TMPDIR/home" vernierLink=y \
      ./MathInstaller -execdir="$out/bin" -targetdir="$out/libexec/Mathematica" -auto -verbose -createdir=y

    # Check if MathInstaller produced any errors
    errLog="$out/libexec/Mathematica/InstallErrors"
    if [ -f "$errLog" ]; then
      echo "Installation errors:"
      cat "$errLog"
      return 1
    fi

    runHook postInstall
  '';

  preFixup = ''
    for bin in $out/libexec/Mathematica/Executables/*; do
      wrapProgram "$bin" ''${wrapProgramFlags[@]}
    done
  '';

  preferLocalBuild = true;
  dontStrip = true;
  autoPatchelfIgnoreMissingDeps = true;
}
