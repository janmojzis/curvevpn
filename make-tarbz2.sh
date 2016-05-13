#!/bin/sh -e

#20121128
#Jan Mojzis
#Public domain.

[ -f make-tarbz2.sh ] || (echo "file make-tarbz2.sh not found"; exit 111;)
[ -f conf-version ] || (echo "file conf-version not found"; exit 111;)

version=`head -1 conf-version`
build="`pwd`/build"
rm -rf "${build}/curvevpn-${version}"
mkdir -p "${build}/curvevpn-${version}"

files=""
for f in `ls | sort`; do
  [ x"${f}" = xbuild ] && continue
  [ x"${f}" = xmake-tarbz2.sh ] && continue
  files="${files} ${f}"
done
cp -pr ${files} "${build}/curvevpn-${version}"
chown -R root:root "${build}/curvevpn-${version}"
(
  cd "${build}"
  tar cf - "curvevpn-${version}" | bzip2 > "curvevpn-${version}.tar.bz2.tmp"
  mv -f "curvevpn-${version}.tar.bz2.tmp" "curvevpn-${version}.tar.bz2"
  rm -rf "curvevpn-${version}"
)
