#!/bin/bash

GEN_SCRIPT="${CONFIGS_DIR}/common-standalone-android.sh"
BOOST_BUILD_TOOLSET="${BOOST_BUILD_TOOLSET:=clang-android}"
OPTS="toolset=${BOOST_BUILD_TOOLSET} target-os=android"

OPTS="${OPTS} --without-context --without-coroutine --without-locale define=BOOST_LOG_USE_COMPILER_TLS"

export NO_BZIP2=1

[ -n "${ANDROID_NDK_HOME}" -a -x "${ANDROID_NDK_HOME}/ndk-build" ] || {
    echo "ANDROID_NDK_HOME is not set to a valid location (${ANDROID_NDK_HOME})"
    return 1
}

ANDROID_PLATFORM="${ANDROID_PLATFORM:-26}"
