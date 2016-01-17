#!/bin/sh -x

# Copyright 2014-2016 Viktor Szakats <https://github.com/vszakats>
# See LICENSE.md

export _NAM
export _VER
export _CPU
export _BAS
export _DST

_NAM="$(basename "$0")"
_NAM="$(echo "${_NAM}" | cut -f 1 -d '.')"
_VER="$1"
_CPU="$2"

(
   cd "${_NAM}" || exit

   # Build

   find . -name '*.o'   -type f -delete
   find . -name '*.a'   -type f -delete
   find . -name '*.lo'  -type f -delete
   find . -name '*.la'  -type f -delete
   find . -name '*.lai' -type f -delete
   find . -name '*.Plo' -type f -delete
   find . -name '*.pc'  -type f -delete

   [ "${_CPU}" = 'win32' ] && export LDFLAGS='-m32'
   [ "${_CPU}" = 'win64' ] && export LDFLAGS='-m64'
   export CFLAGS="${LDFLAGS} -U__STRICT_ANSI__ -DNGHTTP2_STATICLIB -fno-ident"
   export CXXFLAGS="${CFLAGS}"
   # Open dummy file descriptor to fix './<script>: line <n>: 0: Bad file descriptor'
   exec 0</dev/null && ./configure --enable-lib-only "--prefix=$(pwd)"
   exec 0</dev/null && mingw32-make "MAKE=$(echo "${_MAK}" | sed -e 's|\\|/|g')"
   exec 0</dev/null && mingw32-make "MAKE=$(echo "${_MAK}" | sed -e 's|\\|/|g')" install

   # Make steps for determinism

   if ls lib/*.a > /dev/null 2>&1 ; then strip -p --enable-deterministic-archives -g lib/*.a ; fi

   readonly _REF='ChangeLog'

   touch -c -r "${_REF}" include/nghttp2/*.*
   touch -c -r "${_REF}" lib/pkgconfig/*.*
   touch -c -r "${_REF}" lib/*.*

   # Create package

   _BAS="${_NAM}-${_VER}-${_CPU}-mingw"
   _DST="$(mktemp -d)/${_BAS}"

   mkdir -p "${_DST}/include/nghttp2"
   mkdir -p "${_DST}/lib/pkgconfig"

   cp -f -p include/nghttp2/*.h "${_DST}/include/nghttp2/"
   cp -f -p ChangeLog           "${_DST}/ChangeLog.txt"
   cp -f -p AUTHORS             "${_DST}/AUTHORS.txt"
   cp -f -p COPYING             "${_DST}/COPYING.txt"
   cp -f -p README.rst          "${_DST}/README.rst"

   if ls lib/*.a            > /dev/null 2>&1 ; then cp -f -p lib/*.a            "${_DST}/lib" ; fi
   if ls lib/*.la           > /dev/null 2>&1 ; then cp -f -p lib/*.la           "${_DST}/lib" ; fi
   if ls lib/*.pc           > /dev/null 2>&1 ; then cp -f -p lib/*.pc           "${_DST}/lib" ; fi
   if ls lib/pkgconfig/*.pc > /dev/null 2>&1 ; then cp -f -p lib/pkgconfig/*.pc "${_DST}/lib/pkgconfig" ; fi

   unix2dos -k "${_DST}"/*.txt
   unix2dos -k "${_DST}"/*.rst

   ../_pack.sh "$(pwd)/${_REF}"
   ../_ul.sh
)
