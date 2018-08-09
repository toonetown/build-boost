#!/bin/bash

LIPO_PATH="$(which lipo)"
GEN_SCRIPT="${CONFIGS_DIR}/common-clang-darwin.sh"
BOOST_BUILD_TOOLSET="${BOOST_BUILD_TOOLSET:=clang-darwin}"
OPTS="toolset=${BOOST_BUILD_TOOLSET}"

CLANG_PATH="$(xcrun -f clang++)"
MIN_OS_VERSION="${MIN_OS_VERSION:-9.0}"
