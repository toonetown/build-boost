#!/bin/bash

OPTS="${OPTS} architecture=arm address-model=32 binary-format=mach-o abi=aapcs"

SDK_PATH="$(xcrun --sdk iphoneos --show-sdk-path)"
SDK_VERSION_NAME="iphoneos"

return 0
