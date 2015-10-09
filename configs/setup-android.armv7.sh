#!/bin/bash

OPTS="${OPTS} architecture=arm"

GCC_ARCH="arm-linux-androideabi"
GCC_PREFIX="arm-linux-androideabi"
CXX_STL_ARCH="armeabi-v7a"
PLATFORM_ARCH="arm"
JAM_FLAGS="<compileflags>-march=armv7-a <compileflags>-mfloat-abi=softfp <compileflags>-mfpu=vfpv3-d16 <compileflags>-mthumb"

return 0
