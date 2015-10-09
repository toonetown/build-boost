#!/bin/bash
cat << EOF > "${PATH_TO_BOOST_DIST}/project-config.jam"
using gcc :
  : ${ANDROID_NDK_HOME}/toolchains/${GCC_ARCH}-${ANDROID_GCC_VERSION}/prebuilt/darwin-x86_64/bin/${GCC_PREFIX}-g++
  : <compileflags>-mandroid ${JAM_FLAGS}
    <compileflags>-std=c++11
    <compileflags>-FPIC
    <compileflags>-isystem${CXX_STL_ROOT}/include
    <compileflags>-isystem${CXX_STL_ROOT}/libs/${CXX_STL_ARCH}/include
    <compileflags>-isystem${CXX_STL_ROOT}/include/backward
    <compileflags>-isystem${ANDROID_NDK_HOME}/platforms/android-${ANDROID_PLATFORM}/arch-${PLATFORM_ARCH}/usr/include
  ;
EOF
