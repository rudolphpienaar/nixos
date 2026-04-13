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
  version = "unstable-2026-03-30";

  src = fetchFromGitHub {
    owner = "d99kris";
    repo = "nchat";
    rev = "c047a1a239d9d737e89a31bf33d53a29b2ab7a2f";
    hash = "sha256-D/HQ7ak27uJjRWJAdq4eTPiC/r4W1byzcPaX+zov328=";
  };

  libcgowm = buildGoModule {
    pname = "nchat-wmchat-libcgowm";
    inherit version src;

    sourceRoot = "${src.name}/lib/wmchat/go";
    vendorHash = "sha256-5Id5+DehV2juLJnEHYvcI67/ykFUQehSrfFW+toZRM0=";

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
    substituteInPlace lib/tgchat/ext/td/CMakeLists.txt       --replace "get_git_head_revision" "#get_git_head_revision"

    substituteInPlace lib/wmchat/CMakeLists.txt       --replace-fail 'add_subdirectory(go)'       'set(GO_LIBRARIES ${libcgowm}/libcgowm.a)${nl}target_include_directories(wmchat PRIVATE ${libcgowm})'

    substituteInPlace lib/wmchat/CMakeLists.txt       --replace-fail 'target_link_libraries(wmchat PUBLIC ref-cgowm ncutil ''${GO_LIBRARIES})'       'target_link_libraries(wmchat PUBLIC ${libcgowm}/libcgowm.a ncutil ''${GO_LIBRARIES})'

    substituteInPlace lib/wmchat/CMakeLists.txt       --replace-fail 'add_dependencies(wmchat ref-cgowm)' '#add_dependencies(wmchat ref-cgowm)'
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
