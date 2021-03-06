#!/bin/bash
cat << EOF > "${PATH_TO_BOOST_DIST}/project-config.jam"
using clang-darwin : : ${CLANG_PATH}
  : <compileflags>-arch <compileflags>${ARCH} <linkflags>-arch <linkflags>${ARCH}
    <compileflags>-m${SDK_VERSION_NAME}-version-min=${MIN_OS_VERSION}
    <linkflags>-m${SDK_VERSION_NAME}-version-min=${MIN_OS_VERSION}
    <compileflags>-isysroot <compileflags>${SDK_PATH} <linkflags>-isysroot <linkflags>${SDK_PATH}
    <compileflags>-fPIC <compileflags>-fembed-bitcode
  ;
EOF
