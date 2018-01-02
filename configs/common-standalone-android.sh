#!/bin/bash

TOOLCHAIN_ROOT="${OBJDIR_ROOT}/objdir-${TARGET}/build/standalone-toolchain"
[ -d "${TOOLCHAIN_ROOT}" ] || {
    echo -n "Preparing standalone toolchain for ${PLATFORM_ARCH} version ${ANDROID_PLATFORM}..."
    "${ANDROID_NDK_HOME}/build/tools/make_standalone_toolchain.py" --arch ${PLATFORM_ARCH} \
                                                                   --api ${ANDROID_PLATFORM} \
                                                                   --stl libc++ \
                                                                   --install-dir "${TOOLCHAIN_ROOT}" || exit $?
    echo "Done"
}

PFIX="${TOOLCHAIN_ROOT}/bin/${HOST}"
cat << EOF > "${PATH_TO_BOOST_DIST}/project-config.jam"
import os ;

using clang : android
  : "${PFIX}-clang++"
  : ${JAM_FLAGS}
    <archiver>${PFIX}-ar
    <ranlib>${PFIX}-ranlib
  ;
EOF
