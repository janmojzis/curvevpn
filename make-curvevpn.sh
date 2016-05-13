#!/bin/sh -e

top="`pwd`"
build="`pwd`/build"
bin="${build}/bin"
lib="$build/lib"
include="$build/include"
work="$build/work"

rm -rf "$build"
mkdir -p "$build"
mkdir -p "$bin"
mkdir -p "$lib"
mkdir -p "$include"

version=`head -1 "${top}/conf-version"`

LANG=C
export LANG

echo "=== `date` === obtaining compiler"
rm -rf "$work"
mkdir -p "$work"
(
  cd "${work}"
  (
    if [ x"${CC}" != x ]; then
      echo "${CC} "
    fi
    cat "${top}/conf-cc"
  ) | while read compiler
  do
    echo 'int main(void) { return 0; }' > try.c
    ${compiler} -o try try.c 2>/dev/null || { echo "=== `date` ===   ${compiler} failed"; continue; }
    echo "=== `date` ===   ${compiler} ok"
    echo "${compiler}" > compiler
    break
  done
)
compiler=`head -1 "${work}/compiler"`
echo "=== `date` === finishing"

echo "=== `date` === checking compiler options"
rm -rf "$work"
mkdir -p "$work"
(
  cd "${work}"
  for i in -Wno-sign-compare -Wno-overlength-strings -Wno-deprecated-declarations -Wno-long-long -Wall -pedantic ${CFLAGS} ${LDFLAGS}; do
    echo 'int main(void) { return 0; }' > try.c
    ${compiler} "$i" -o try try.c 2>/dev/null || { echo "=== `date` ===   $i failed"; continue; }
    options="$i $options"
    echo "=== `date` ===   $i ok"
  done
  echo $options > options
)
compilerorig=${compiler}
compiler="${compiler} `cat ${work}/options`"
echo "=== `date` ===   $compiler"
echo "=== `date` === finishing"

echo "=== `date` === checking libs"
rm -rf "$work"
mkdir -p "$work"
(
  cd "$work"
  for i in '-lrt' '-lsocket -lnsl' ${LIBS}; do
    echo 'int main(void) { return 0; }' > try.c
    ${compiler} $i -o try try.c 2>/dev/null || { echo "=== `date` ===   $i failed"; continue; }
    syslibs="$i $syslibs"
    echo "=== `date` ===   $i ok"
  done
  echo $syslibs > syslibs
)
libs=`cat "${work}/syslibs"`
echo "=== `date` === finishing"

mkdir -p "$work"
cp -pr sysdep/* "$work"
(
  cd "$work"
  sh list | (
    while read target source
    do
      [ -f "${include}/${target}" ] && continue
      rm -f "$source" "$target.tmp" 
      ${compiler} -O0 -o "$source" "$source.c" $libs 2>/dev/null || continue
      ./$source > "$target.tmp" 2>/dev/null || continue
      cp "$target.tmp" "$include/$target"
      echo "=== `date` ===   $target $source"
    done
  )
)
echo "=== `date` === finishing"

echo "=== `date` === starting curvecp"
rm -rf "$work"
mkdir -p "$work"
cp -pr curvecp/* "$work"
(
  cd "$work"
  cat SOURCES\
  | while read x
  do
    $compiler "-DVERSION=\"${version}\"" -I"$include" -c "$x.c" || exit 111
    #echo "=== `date` ===   $x.o ok"
  done
  ar cr libcurvecp.a `cat LIBS` || exit 111

  #echo "=== `date` ===   libcurvecp.a ok"

  cat TARGETS \
  | while read x y
  do
    $compiler -I"$include" -o "$x" "$x.o" libcurvecp.a $libs || exit 111
    echo "=== `date` ===   $x ok"
    cp -p "$x" "$bin/$y";
  done
  echo "=== `date` === finishing"
) || exit 111

echo "=== `date` === starting tun"
rm -rf "$work"
mkdir -p "$work"
cp -pr tun/* "$work"
(
  cd "$work"
  sh list | (
    while read target source
    do
      [ -f "${target}" ] && continue
      rm -f "$source" "$target.tmp" 
      ${compiler} -O0 -o "$source" "$source.c" $libs 2>/dev/null || continue
      ./$source > "$target.tmp" 2>/dev/null || continue
      cp "$target.tmp" "$target"
      echo "=== `date` ===   $target $source"
    done
  )
)
echo "=== `date` === finishing"

echo "=== `date` === starting vpn"
cp -pr vpn/* "$work"
(
  cd "$work"
  cat SOURCES\
  | while read x
  do
    $compiler "-DVERSION=\"${version}\"" -I"$include" -c "$x.c" || exit 111
    #echo "=== `date` ===   $x.o ok"
  done
  ar cr libvpn.a `cat LIBS` || exit 111

  #echo "=== `date` ===   libvpn.a ok"

  cat TARGETS \
  | while read x
  do
    $compiler -I"$include" -o "$x" "$x.o" libvpn.a $libs || exit 111
    echo "=== `date` ===   $x ok"
    cp -p "$x" "$bin/$x";
  done
  echo "=== `date` === finishing"
) || exit 111

