{
  lib,
  stdenv,
  buildGoModule,
  fetchFromGitHub,
  file,
  ncurses,
  openssl,
  readline,
  sqlite,
  zlib,
  cmake,
  gperf,
  go,
  withWhatsApp ? true,
}:

let
  version = "unstable-2026-08-02";

  src = fetchFromGitHub {
    owner = "d99kris";
    repo = "nchat";
    rev = "6a56ffe9cbecbe83dabe9c2238a9d38fa64efc11";
    hash = "sha256-zj/lIELniG83VSsXeDdp3Zrn78qRUA65ceQKI5XFDS8=";
  };

  libcgowm = buildGoModule {
    pname = "nchat-wmchat-libcgowm";
    inherit version src;

    sourceRoot = "${src.name}/lib/wmchat/go";
    vendorHash = "sha256-750sFLZxQjKkUoOnLoP5lRkKFtDubqNyvfvK6J2Wb5o=";

    buildPhase = ''
      runHook preBuild

      mkdir -p $out/
      go build -o $out/ -buildmode=c-archive
      mv $out/go.a $out/libcgowm.a
      ln -s $out/libcgowm.a $out/libref-cgowm.a
      mv $out/go.h $out/libcgowm.h

      runHook postBuild
    '';
  };
in
stdenv.mkDerivation rec {
  pname = "nchat";
  inherit version src;

  nl = "\n";
  postPatch = ''
    substituteInPlace lib/tgchat/ext/td/CMakeLists.txt       --replace-warn "get_git_head_revision" "#get_git_head_revision"

    substituteInPlace lib/wmchat/CMakeLists.txt       --replace-fail 'add_subdirectory(go)'       'set(GO_LIBRARIES ${libcgowm}/libcgowm.a)${nl}target_include_directories(wmchat PRIVATE ${libcgowm})'

    substituteInPlace lib/wmchat/CMakeLists.txt       --replace-fail 'set(WMCHAT_GOLIB ref-cgowm)'       'set(WMCHAT_GOLIB ${libcgowm}/libcgowm.a)'

    substituteInPlace lib/wmchat/CMakeLists.txt       --replace-fail 'add_dependencies(wmchat ''${WMCHAT_GOLIB})' '#add_dependencies(wmchat ''${WMCHAT_GOLIB})'
  '';

  nativeBuildInputs = [ cmake gperf go libcgowm ];

  buildInputs = [ file ncurses openssl readline sqlite zlib ];

  cmakeFlags = [
    (lib.cmakeFeature "CMAKE_INSTALL_LIBDIR" "lib")
    (lib.cmakeBool "HAS_WHATSAPP" withWhatsApp)
  ];

  meta = {
    description = "Terminal-based chat client with support for Telegram and WhatsApp";
    homepage = "https://github.com/d99kris/nchat";
    license = lib.licenses.mit;
    mainProgram = "nchat";
    platforms = lib.platforms.unix;
  };
}
