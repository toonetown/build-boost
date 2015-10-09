#!/bin/bash

GEN_SCRIPT="${CONFIGS_DIR}/common-gcc-android.sh"
BOOST_BUILD_TOOLSET="${BOOST_BUILD_TOOLSET:=gcc}"
OPTS="toolset=${BOOST_BUILD_TOOLSET} target-os=linux"

OPTS="${OPTS} --without-context --without-coroutine --without-coroutine2 --without-locale"
export NO_BZIP2=1

[ -n "${ANDROID_NDK_HOME}" -a -x "${ANDROID_NDK_HOME}/ndk-build" ] || {
    echo "ANDROID_NDK_HOME is not set to a valid location (${ANDROID_NDK_HOME})"
    return 1
}

ANDROID_GCC_VERSION="${ANDROID_GCC_VERSION:-4.9}"
ANDROID_PLATFORM="${ANDROID_PLATFORM:-15}"
CXX_STL_ROOT="${ANDROID_NDK_HOME}/sources/cxx-stl/gnu-libstdc++/${ANDROID_GCC_VERSION}"

return 0
