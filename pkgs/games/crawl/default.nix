{ stdenv, fetchFromGitHub, which, sqlite, lua5_1, perl, zlib, pkgconfig, ncurses
, dejavu_fonts, libpng, SDL2, SDL2_image, mesa, freetype
, tileMode ? false
}:

stdenv.mkDerivation rec {
  name = "crawl-${version}" + (if tileMode then "-tiles" else "");
  version = "0.18.1";

  src = fetchFromGitHub {
    owner = "crawl-ref";
    repo = "crawl-ref";
    rev = version;
    sha256 = "1cg5mxhx0lfhadls6n8avcpkjx08nqf1y085li97zqxl3gjaj64j";
  };

  patches = [ ./crawl_purify.patch ];

  nativeBuildInputs = [ pkgconfig which perl ];

  # Still unstable with luajit
  buildInputs = [ lua5_1 zlib sqlite ncurses ]
             ++ stdenv.lib.optionals tileMode
                [ libpng SDL2 SDL2_image freetype mesa ];

  preBuild = ''
    cd crawl-ref/source
    echo "${version}" > util/release_ver
    for i in util/*; do
      patchShebangs $i
    done
    patchShebangs util/gen-mi-enum
    rm -rf contrib
  '';

  makeFlags = [ "prefix=$(out)" "FORCE_CC=gcc" "FORCE_CXX=g++" "HOSTCXX=g++"
                "SAVEDIR=~/.crawl" "sqlite=${sqlite.dev}" ]
           ++ stdenv.lib.optionals tileMode [ "TILES=y" "dejavu_fonts=${dejavu_fonts}" ];

  postInstall = if tileMode then "mv $out/bin/crawl $out/bin/crawl-tiles" else "";

  enableParallelBuilding = true;

  meta = with stdenv.lib; {
    description = "Open-source, single-player, role-playing roguelike game";
    homepage = http://crawl.develz.org/;
    longDescription = ''
      Open-source, single-player, role-playing roguelike game of exploration and
      treasure-hunting in dungeons filled with dangerous and unfriendly monsters
      in a quest to rescue the mystifyingly fabulous Orb of Zot.
    '';
    platforms = platforms.linux;
    license = with licenses; [ gpl2Plus bsd2 bsd3 mit licenses.zlib cc0 ];
    maintainers = [ maintainers.abbradar ];
  };
}
