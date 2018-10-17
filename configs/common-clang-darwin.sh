#!/bin/bash
CXX_VERSION="${CXX_VERSION:-17}"

cat << EOF > "${PATH_TO_BOOST_DIST}/project-config.jam"
using clang-darwin : : ${CLANG_PATH}
  : <compileflags>-arch <compileflags>${ARCH} <linkflags>-arch <linkflags>${ARCH}
    <compileflags>-m${SDK_VERSION_NAME}-version-min=${MIN_OS_VERSION}
    <linkflags>-m${SDK_VERSION_NAME}-version-min=${MIN_OS_VERSION}
    <compileflags>-isysroot <compileflags>${SDK_PATH} <linkflags>-isysroot <linkflags>${SDK_PATH}
    <cxxflags>-std=c++${CXX_VERSION} <cxxflags>-stdlib=libc++ <linkflags>-stdlib=libc++
    <compileflags>-fPIC <compileflags>-fembed-bitcode
    <cxxflags>-fvisibility=default
  ;
EOF
