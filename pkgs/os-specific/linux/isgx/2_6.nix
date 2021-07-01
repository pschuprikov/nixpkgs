{ stdenv, lib, fetchFromGitHub, fetchpatch, kernel, kernelAtLeast }:

stdenv.mkDerivation rec {
  name = "isgx-${version}-${kernel.version}";
  version = "2.6";

  src = fetchFromGitHub {
    owner = "intel";
    repo = "linux-sgx-driver";
    rev = "sgx_driver_${version}";
    hash = "sha256-cp11M4amY3WlXE+CPTS6uHgfQ1BjFw8PwVH+LW44sXg=";
  };

  patches = [
    # Fixes build with kernel >= 5.8
    (fetchpatch {
      url = "https://github.com/intel/linux-sgx-driver/commit/276c5c6a064d22358542f5e0aa96b1c0ace5d695.patch";
      sha256 = "sha256-PmchqYENIbnJ51G/tkdap/g20LUrJEoQ4rDtqy6hj24=";
    })
    # Fixes detection with kernel >= 5.11
    (fetchpatch {
      url = "https://github.com/intel/linux-sgx-driver/commit/ed2c256929962db1a8805db53bed09bb8f2f4de3.patch";
      sha256 = "sha256-MRbgS4U8FTCP1J1n+rhsvbXxKDytfl6B7YlT9Izq05U=";
    })
    # Fix for newer kernels and 2.6 isgx
    (fetchpatch {
      url = "https://github.com/intel/linux-sgx-driver/commit/329facdacaca1f8608a98af13bc3f5a22e52d000.patch";
      sha256 = "sha256-m2ttWHRZvtxfcEOQk0neVY8eba8qZCs2G+CBisoHmeU=";
    })
  ];

  hardeningDisable = [ "pic" ];

  nativeBuildInputs = kernel.moduleBuildDependencies;

  makeFlags = [
    "KDIR=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
  ];

  installPhase = ''
    runHook preInstall
    install -D isgx.ko -t $out/lib/modules/${kernel.modDirVersion}/kernel/drivers/intel/sgx
    runHook postInstall
  '';

  meta = with lib; {
    description = "Intel SGX Linux Driver";
    longDescription = ''
      The linux-sgx-driver project (isgx) hosts an out-of-tree driver
      for the Linux* Intel(R) SGX software stack, which would be used
      until the driver upstreaming process is complete (before 5.11.0).

      It is used to support Enhanced Privacy Identification (EPID)
      based attestation on the platforms without Flexible Launch Control.
    '';
    homepage = "https://github.com/intel/linux-sgx-driver";
    license = with licenses; [ bsd3 /* OR */ gpl2Only ];
    maintainers = with maintainers; [ oxalica ];
    platforms = [ "x86_64-linux" ];
  };
}
