{ stdenv, fetchFromGitHub
, pkgconfig, autoreconfHook
, openssl, db48, boost, zlib, miniupnpc
, glib, protobuf, utillinux, qt4, qrencode
, AppKit
, withGui ? true, libevent
}:

with stdenv.lib;

stdenv.mkDerivation rec {

  name = "litecoin" + (toString (optional (!withGui) "d")) + "-" + version;
  version = "0.16.2";

  src = fetchFromGitHub {
    owner = "litecoin-project";
    repo = "litecoin";
    rev = "v${version}";
    sha256 = "0xfwh7cxxz6w8kgr4kl48w3zm81n1hv8fxb5l9zx3460im1ffgy6";
  };

  nativeBuildInputs = [ pkgconfig autoreconfHook ];
  buildInputs = [ openssl db48 boost zlib
                  miniupnpc glib protobuf utillinux libevent ]
                  ++ optionals stdenv.isDarwin [ AppKit ]
                  ++ optionals withGui [ qt4 qrencode ];

  configureFlags = [ "--with-boost-libdir=${boost.out}/lib" ]
                     ++ optionals withGui [ "--with-gui=qt4" ];

  enableParallelBuilding = true;

  meta = {
    description = "A lite version of Bitcoin using scrypt as a proof-of-work algorithm";
    longDescription= ''
      Litecoin is a peer-to-peer Internet currency that enables instant payments
      to anyone in the world. It is based on the Bitcoin protocol but differs
      from Bitcoin in that it can be efficiently mined with consumer-grade hardware.
      Litecoin provides faster transaction confirmations (2.5 minutes on average)
      and uses a memory-hard, scrypt-based mining proof-of-work algorithm to target
      the regular computers and GPUs most people already have.
      The Litecoin network is scheduled to produce 84 million currency units.
    '';
    homepage = https://litecoin.org/;
    platforms = platforms.unix;
    license = licenses.mit;
    broken = stdenv.isDarwin;
    maintainers = with maintainers; [ offline AndersonTorres ];
  };
}
