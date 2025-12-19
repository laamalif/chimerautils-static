#!/bin/bash
set -e

arch=$(uname -m)

apt update && apt install -y \
  lsb-release libzstd-dev liblzma-dev libbz2-dev zlib1g-dev libacl1-dev \
  libtinfo-dev libncurses-dev libbsd-dev pkg-config cmake byacc git \
  build-essential clang lld autoconf libtool meson flex wget curl

export CC=clang
export CXX=clang++
export LD=ld.lld
export CXXFLAGS="-std=c++17"
export LDFLAGS="-ltinfo"

# -------------------------------
# Build libxo
# -------------------------------
git clone https://github.com/Juniper/libxo.git
cd libxo
sh bin/setup.sh
cd build
../configure --enable-static --disable-shared
make -j$(nproc)
make install
cd

# -------------------------------
# Build LibreSSL
# -------------------------------
curl -O https://ftp.openbsd.org/pub/OpenBSD/LibreSSL/libressl-4.1.0.tar.gz
tar -xf libressl-4.1.0.tar.gz
cd libressl-4.1.0
./configure --enable-static --disable-shared 
make -j$(nproc)
make install
cd

# -------------------------------
# Debian / Ubuntu deb-src fix
# -------------------------------
if grep -qi "ubuntu" /etc/os-release; then
  echo "🟡 Detected Ubuntu – enabling deb-src in classic format"
  release=$(lsb_release -cs)

  for line in \
    "deb-src http://ports.ubuntu.com/ubuntu-ports $release main" \
    "deb-src http://ports.ubuntu.com/ubuntu-ports $release-updates main"
  do
    grep -qxF "$line" /etc/apt/sources.list || echo "$line" >> /etc/apt/sources.list
  done

else
  echo "🟢 Detected Debian – adding deb-src in deb822 format"

  # IMPORTANT FIX: Use .pgp to match GitHub runner’s existing Signed-By
  cat <<EOF | tee /etc/apt/sources.list.d/debian-sources-debsrc.sources > /dev/null
Types: deb-src
URIs: http://deb.debian.org/debian
Suites: trixie
Components: main
Signed-By: /usr/share/keyrings/debian-archive-keyring.pgp
EOF

fi

apt update

# -------------------------------
# Build libedit (static)
# -------------------------------
apt source libedit-dev
cd libedit-3.1-*
./configure --enable-static --disable-shared
make -j$(nproc)
make install
cd

# -------------------------------
# Build chimerautils
# -------------------------------
git clone https://github.com/chimera-linux/chimerautils.git
cd chimerautils

version=$(git describe --tags --abbrev=0)

rm -rf build && mkdir build && cd build
meson setup .. --buildtype=release --default-library=static
ninja -j$(nproc)

mkdir release

# -------------------------------
# Build each binary statically
# -------------------------------

clang -static -o release/find \
  src.freebsd/findutils/find/find.p/meson-generated_getdate.c.o \
  src.freebsd/findutils/find/find.p/find.c.o \
  src.freebsd/findutils/find/find.p/function.c.o \
  src.freebsd/findutils/find/find.p/ls.c.o \
  src.freebsd/findutils/find/find.p/main.c.o \
  src.freebsd/findutils/find/find.p/misc.c.o \
  src.freebsd/findutils/find/find.p/operator.c.o \
  src.freebsd/findutils/find/find.p/option.c.o \
  src.freebsd/compat/libcompat.a \
  src.freebsd/util/libutil_static.a \
  -L/usr/local/libedit-static/lib \
  -I/usr/local/libedit-static/include \
  -ledit -lacl -lz -lzstd -llzma -lbz2 -lcrypto -lssl -ltinfo -lncursesw -lxo -lm -static

clang -static -o release/fetch \
  src.freebsd/fetch/fetch.p/fetch.c.o \
  src.freebsd/libfetch/liblibfetch.a \
  src.freebsd/compat/libcompat.a \
  /usr/local/lib/libssl.a \
  /usr/local/lib/libcrypto.a \
  -lresolv -lz -static

clang -static -o release/xargs \
  src.freebsd/findutils/xargs/xargs.p/strnsubst.c.o \
  src.freebsd/findutils/xargs/xargs.p/xargs.c.o \
  src.freebsd/compat/libcompat.a \
  -static

clang -static -o release/grep \
  src.freebsd/grep/grep.p/grep.c.o \
  src.freebsd/grep/grep.p/file.c.o \
  src.freebsd/grep/grep.p/queue.c.o \
  src.freebsd/grep/grep.p/util.c.o \
  src.freebsd/compat/libcompat.a \
  src.freebsd/util/libutil_static.a \
  -static

clang -static -o release/jot \
  src.freebsd/jot/jot.p/jot.c.o \
  src.freebsd/compat/libcompat.a \
  -static

clang -static -o release/nc \
  src.freebsd/netcat/nc.p/netcat.c.o \
  src.freebsd/netcat/nc.p/atomicio.c.o \
  src.freebsd/netcat/nc.p/socks.c.o \
  src.freebsd/compat/libcompat.a \
  -static

clang -static -o release/telnet \
  src.freebsd/telnet/telnet.p/telnet_commands.c.o \
  src.freebsd/telnet/telnet.p/telnet_main.c.o \
  src.freebsd/telnet/telnet.p/telnet_network.c.o \
  src.freebsd/telnet/telnet.p/telnet_ring.c.o \
  src.freebsd/telnet/telnet.p/telnet_sys_bsd.c.o \
  src.freebsd/telnet/telnet.p/telnet_telnet.c.o \
  src.freebsd/telnet/telnet.p/telnet_terminal.c.o \
  src.freebsd/telnet/telnet.p/telnet_utilities.c.o \
  src.freebsd/telnet/telnet.p/telnet_authenc.c.o \
  src.freebsd/telnet/telnet.p/libtelnet_genget.c.o \
  src.freebsd/telnet/telnet.p/libtelnet_misc.c.o \
  src.freebsd/telnet/telnet.p/libtelnet_encrypt.c.o \
  src.freebsd/telnet/telnet.p/libtelnet_auth.c.o \
  src.freebsd/telnet/telnet.p/libtelnet_enc_des.c.o \
  src.freebsd/telnet/telnet.p/libtelnet_sra.c.o \
  src.freebsd/telnet/telnet.p/libtelnet_pk.c.o \
  src.freebsd/libmp/liblibmp.a \
  src.freebsd/compat/libcompat.a \
  /usr/local/lib/libcrypto.a \
  -lncursesw -ltinfo -static

clang -static -o release/awk \
  src.freebsd/awk/awk.p/meson-generated_.._awkgram.tab.c.o \
  src.freebsd/awk/awk.p/meson-generated_.._proctab.c.o \
  src.freebsd/awk/awk.p/b.c.o \
  src.freebsd/awk/awk.p/lex.c.o \
  src.freebsd/awk/awk.p/lib.c.o \
  src.freebsd/awk/awk.p/main.c.o \
  src.freebsd/awk/awk.p/parse.c.o \
  src.freebsd/awk/awk.p/run.c.o \
  src.freebsd/awk/awk.p/tran.c.o \
  -lm -static

clang -static -o release/gzip \
  src.freebsd/gzip/gzip.p/gzip.c.o \
  src.freebsd/compat/libcompat.a \
  src.freebsd/util/libutil_static.a \
  -lz -llzma -lbz2 -lzstd -static

clang -static -o release/diff \
  src.freebsd/diffutils/diff/diff.p/diff.c.o \
  src.freebsd/diffutils/diff/diff.p/diffdir.c.o \
  src.freebsd/diffutils/diff/diff.p/diffreg.c.o \
  src.freebsd/diffutils/diff/diff.p/pr.c.o \
  src.freebsd/diffutils/diff/diff.p/xmalloc.c.o \
  src.freebsd/compat/libcompat.a \
  -lm -static

clang -static -o release/diff3 \
  src.freebsd/diffutils/diff3/diff3.p/diff3.c.o \
  -static

clang -static -o release/sdiff \
  src.freebsd/diffutils/sdiff/sdiff.p/sdiff.c.o \
  src.freebsd/diffutils/sdiff/sdiff.p/edit.c.o \
  src.freebsd/compat/libcompat.a \
  -static

clang -static -o release/sh \
  src.freebsd/sh/sh.p/meson-generated_.._builtins.c.o \
  src.freebsd/sh/sh.p/meson-generated_.._nodes.c.o \
  src.freebsd/sh/sh.p/meson-generated_.._syntax.c.o \
  src.freebsd/sh/sh.p/alias.c.o \
  src.freebsd/sh/sh.p/arith_yacc.c.o \
  src.freebsd/sh/sh.p/arith_yylex.c.o \
  src.freebsd/sh/sh.p/cd.c.o \
  src.freebsd/sh/sh.p/error.c.o \
  src.freebsd/sh/sh.p/eval.c.o \
  src.freebsd/sh/sh.p/exec.c.o \
  src.freebsd/sh/sh.p/expand.c.o \
  src.freebsd/sh/sh.p/histedit.c.o \
  src.freebsd/sh/sh.p/input.c.o \
  src.freebsd/sh/sh.p/jobs.c.o \
  src.freebsd/sh/sh.p/mail.c.o \
  src.freebsd/sh/sh.p/main.c.o \
  src.freebsd/sh/sh.p/memalloc.c.o \
  src.freebsd/sh/sh.p/miscbltin.c.o \
  src.freebsd/sh/sh.p/mystring.c.o \
  src.freebsd/sh/sh.p/options.c.o \
  src.freebsd/sh/sh.p/output.c.o \
  src.freebsd/sh/sh.p/parser.c.o \
  src.freebsd/sh/sh.p/redir.c.o \
  src.freebsd/sh/sh.p/show.c.o \
  src.freebsd/sh/sh.p/trap.c.o \
  src.freebsd/sh/sh.p/var.c.o \
  src.freebsd/sh/libbltins_lib.a \
  src.freebsd/compat/libcompat.a \
  -ledit -lbsd -ltinfo -static

clang -static -o release/patch \
  src.freebsd/patch/patch.p/patch.c.o \
  src.freebsd/patch/patch.p/backupfile.c.o \
  src.freebsd/patch/patch.p/inp.c.o \
  src.freebsd/patch/patch.p/mkpath.c.o \
  src.freebsd/patch/patch.p/pch.c.o \
  src.freebsd/patch/patch.p/util.c.o \
  src.freebsd/compat/libcompat.a \
  -static

clang -static -o release/sed \
  src.freebsd/sed/sed.p/compile.c.o \
  src.freebsd/sed/sed.p/main.c.o \
  src.freebsd/sed/sed.p/misc.c.o \
  src.freebsd/sed/sed.p/process.c.o \
  src.freebsd/compat/libcompat.a \
  -static

clang -static -o release/vis \
  src.freebsd/vis/vis.p/vis.c.o \
  src.freebsd/vis/vis.p/foldit.c.o \
  src.freebsd/compat/libcompat.a \
  -static

clang -static -o release/unvis \
  src.freebsd/unvis/unvis.p/unvis.c.o \
  src.freebsd/compat/libcompat.a \
  -static

strip release/*
echo "✅ Binaries built and stripped."

mv release chimerautils

# -------------------------------
# Package output
# -------------------------------
output_dir=/src/artifacts
mkdir -p "$output_dir"

case "$arch" in
  x86_64) output_arch="amd64" ;;
  aarch64|arm64) output_arch="arm64" ;;
  *) output_arch="$arch" ;;
esac

tar -czf "$output_dir/chimerautils-${output_arch}.tar.gz" chimerautils

echo "📦 Archive ready: chimerautils-${output_arch}.tar.gz"
echo "🔍 Generating SHA256 checksum..."
sha256sum "$output_dir/chimerautils-${output_arch}.tar.gz" | tee "$output_dir/chimerautils-${output_arch}.sha256"
