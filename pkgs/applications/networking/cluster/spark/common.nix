{ version, sha256, depsSha256 }:
{ lib, stdenv, runCommand, fetchzip, makeWrapper, jdk, pythonPackages, coreutils
, inetutils, hadoop, procps, maven, RSupport ? true, R, scalaVersion ? "2.12" }:

with lib;

let
  pname = "spark";

  src = fetchzip {
    url = "mirror://apache/spark/${pname}-${version}/${pname}-${version}.tgz";
    inherit sha256;
  };

  configurePhase = ''
    ./dev/change-scala-version.sh ${scalaVersion}
  '';

  patchPhase = ''
    patchShebangs ./dev
  '';

  mavenFlags =
    "-Dmaven.test.skip -DskipTests -Dzinc.dir=$PWD -Dhadoop.version=${hadoop.version} -Pyarn -Pscala-${scalaVersion} -Phadoop-provided";

  deps = stdenv.mkDerivation {
    pname = "${pname}-deps";
    inherit version src patchPhase configurePhase;
    nativeBuildInputs = [ maven jdk ];

    buildPhase = ''
      ./dev/make-distribution.sh --mvn mvn ${mavenFlags} -Dmaven.repo.local="$out/.m2"
    '';

    installPhase =
      "find $out/.m2 -type f -regex '.+\\(\\.lastUpdated\\|resolver-status\\.properties\\|_remote\\.repositories\\)' -delete";

    outputHashAlgo = "sha256";
    outputHashMode = "recursive";
    outputHash = depsSha256;
  };

  dist-bin = stdenv.mkDerivation {
    pname = "${pname}-bin";
    inherit version src configurePhase;

    patchPhase = patchPhase + ''
      cp -dpR ${deps}/.m2 ./
      chmod +w -R .m2
    '';

    buildPhase = ''
      ./dev/make-distribution.sh --mvn mvn ${mavenFlags} -Dmaven.repo.local="$PWD/.m2" --offline
    '';

    installPhase = ''
      mkdir $out
      cp -R dist/* $out/

      for n in $(find $out/bin -type f ! -name "*.*"); do
        substituteInPlace "$n" --replace dirname ${coreutils.out}/bin/dirname
      done

      for n in $(find $out/sbin/ -type f -executable); do
        substituteInPlace "$n" \
          --replace dirname ${coreutils}/bin/dirname \
          --replace hostname ${inetutils}/bin/hostname \
          --replace ps ${procps}/bin/ps
      done
    '';

    nativeBuildInputs = [ maven ];

    buildInputs = [ jdk ];
  };

in runCommand "${pname}-${version}" {
  passthru = { inherit deps dist-bin hadoop; };

  buildInputs = [ makeWrapper ];

  meta = {
    description =
      "Apache Spark is a fast and general engine for large-scale data processing";
    homepage = "http://spark.apache.org";
    license = lib.licenses.asl20;
    platforms = lib.platforms.all;
    maintainers = with maintainers; [ thoughtpolice offline kamilchm ];
    repositories.git = "git://git.apache.org/spark.git";
  };
} ''
  mkdir -p $out/bin

  for n in $(find ${dist-bin}/sbin/ -type f -executable); do
    makeWrapper "$n" "$out/bin/$(basename $n)"\
      --set JAVA_HOME ${jdk.jre.home} \
      --set SPARK_HOME ${dist-bin} \
      --set SPARK_DIST_CLASSPATH "$(${hadoop}/bin/hadoop classpath)"
  done
''

