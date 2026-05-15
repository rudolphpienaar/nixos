{
  lib,
  stdenv,
  autoPatchelfHook,
  copyDesktopItems,
  makeDesktopItem,
  dpkg,
  avahi,
  alsa-lib,
  libdrm,
  qt5,
  zlib,
  xorg,
}:

stdenv.mkDerivation rec {
  pname = "iriunwebcam";
  version = "2.9.1";

  src = ../distfiles/iriunwebcam-2.9.1.deb;

  nativeBuildInputs = [
    autoPatchelfHook
    qt5.wrapQtAppsHook
    copyDesktopItems
    dpkg
  ];

  buildInputs = [
    avahi
    alsa-lib
    libdrm
    qt5.qtbase
    zlib
    xorg.libX11
    xorg.libXext
    xorg.libXfixes
    xorg.libXrender
    xorg.libxcb
    stdenv.cc.cc.lib
  ];

  unpackPhase = ''
    runHook preUnpack
    dpkg-deb -x "$src" .
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    install -Dm0755 usr/local/bin/iriunwebcam $out/bin/iriunwebcam
    install -Dm0644 usr/share/pixmaps/iriunwebcam.png $out/share/pixmaps/iriunwebcam.png

    substituteInPlace usr/share/applications/iriunwebcam.desktop \
      --replace-fail '/usr/local/bin/iriunwebcam' "$out/bin/iriunwebcam"
    install -Dm0644 usr/share/applications/iriunwebcam.desktop $out/share/applications/iriunwebcam.desktop

    runHook postInstall
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "iriunwebcam";
      desktopName = "Iriun Webcam";
      exec = "iriunwebcam";
      icon = "iriunwebcam";
      categories = [ "AudioVideo" "Video" "Network" ];
      startupWMClass = "iriunwebcam";
    })
  ];

  meta = {
    description = "Use a phone camera as a wireless webcam";
    homepage = "https://www.iriun.com/";
    license = lib.licenses.unfreeRedistributable;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "iriunwebcam";
  };
}
