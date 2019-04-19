#!/bin/bash

LIPO_PATH="$(which lipo)"
GEN_SCRIPT="${CONFIGS_DIR}/common-clang-darwin.sh"
BOOST_BUILD_TOOLSET="${BOOST_BUILD_TOOLSET:=clang-darwin}"
CXX_VERSION="${CXX_VERSION:-17}"
COMPILER_VISIBILITY="${COMPILER_VISIBILITY:-hidden}"

OPTS="toolset=${BOOST_BUILD_TOOLSET} architecture=x86 define=BOOST_LOG_USE_COMPILER_TLS \
      visibility=${COMPILER_VISIBILITY} \
      cxxstd=${CXX_VERSION}"

CLANG_PATH="$(xcrun -f clang++)"
SDK_PATH="$(xcrun --sdk macosx --show-sdk-path)"
SDK_VERSION_NAME="macosx"
MIN_OS_VERSION="${MIN_OS_VERSION:-10.13}"
