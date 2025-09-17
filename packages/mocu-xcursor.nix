{
  fetchFromGitHub,
  stdenvNoCC,

  librsvg,
  xmlstarlet,
  xorg
}: stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "mocu-xcursor";
  version = "1.1";

  src = fetchFromGitHub {
    owner = "sevmeyer";
    repo = "mocu-xcursor";
    rev = finalAttrs.version;
    hash = "sha256-DVHPUCq3y/f1cVHHKg/qXYr/pGGUcP98RhFuGzNhT/I=";
  };

  nativeBuildInputs = [
    librsvg
    xmlstarlet
    xorg.xcursorgen
  ];

  buildPhase = ''
    runHook preBuild

    cat << END >> src/themes.txt
    Mocu-Iceberg-White-Right #c6c8d1 #07080a #000000 right
    Mocu-Iceberg-White-Left  #c6c8d1 #07080a #000000 left
    Mocu-Iceberg-Black-Right #07080a #c6c8d1 #000000 right
    Mocu-Iceberg-Black-Left  #07080a #c6c8d1 #000000 left
    END

    patchShebangs make.sh
    ./make.sh

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/icons
    mv dist/* $out/share/icons

    runHook postInstall
  '';
})
