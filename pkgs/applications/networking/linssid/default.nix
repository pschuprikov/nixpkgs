{ stdenv, fetchurl, qtbase, qtsvg, qmake, pkgconfig, boost, wirelesstools, iw, qwt, makeWrapper }:

stdenv.mkDerivation rec {
  name = "linssid-${version}";
  version = "3.6";

  src = fetchurl {
    url = "mirror://sourceforge/project/linssid/LinSSID_${version}/linssid_${version}.orig.tar.gz";
    sha256 = "1774wcr90jk0zil3psd545zz60l5f57bys366492b3vh7zliwc2p";
  };

  nativeBuildInputs = [ pkgconfig qmake makeWrapper ];
  buildInputs = [ qtbase qtsvg boost qwt ];

  postPatch = ''
    sed -e "s|/usr/include/qwt|${qwt}/include|" -i linssid-app/linssid-app.pro
    sed -e "s|/usr/include/|/nonexistent/|g" -i linssid-app/*.pro
    sed -e 's|^LIBS .*= .*/usr/lib/libqwt.*|LIBS += -lqwt|' \
        -e "s|/usr|$out|g" \
        -i linssid-app/linssid-app.pro linssid-app/linssid.desktop linssid-app/linssid-pkexec
    sed -e "s|pkexec|/run/wrappers/bin/pkexec|" -i linssid-app/linssid-pkexec
    sed -e "s|\.\./\.\./\.\./\.\./usr|$out|g" -i linssid-app/*.ui
  '';

  postInstall = ''
    wrapProgram $out/sbin/linssid \
      --prefix QT_PLUGIN_PATH : ${qtbase}/${qtbase.qtPluginPrefix} \
      --prefix PATH : ${stdenv.lib.makeBinPath [ wirelesstools iw ]}  
      '';

  meta = with stdenv.lib; {
    description = "Graphical wireless scanning for Linux";
    homepage = https://sourceforge.net/projects/linssid/;
    license = licenses.gpl3;
    platforms = platforms.linux;
    maintainers = [ maintainers.bjornfor ];
  };
}
