#!/bin/bash

OPTS="${OPTS} architecture=arm"

PLATFORM_ARCH="arm"
HOST="arm-linux-androideabi"
JAM_FLAGS="<compileflags>-march=armv7-a \
           <compileflags>-mfloat-abi=softfp \
           <compileflags>-mfpu=vfpv3-d16 \
           <compileflags>-mthumb"
