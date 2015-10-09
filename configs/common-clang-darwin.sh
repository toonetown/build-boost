cat << EOF > "${PATH_TO_BOOST_DIST}/project-config.jam"
using clang-darwin : : ${CLANG_PATH}
  : <compileflags>-arch <compileflags>${ARCH}
    <compileflags>-m${SDK_VERSION_NAME}-version-min=${MIN_OS_VERSION}
    <cxxflags>-std=c++11 <cxxflags>-stdlib=libc++
    <compileflags>-fPIC <compileflags>-fembed-bitcode
    <compileflags>-isysroot <compileflags>${SDK_PATH}
    <linkflags>-arch <linkflags>${ARCH}
    <linkflags>-m${SDK_VERSION_NAME}-version-min=${MIN_OS_VERSION}
    <linkflags>-stdlib=libc++
    <linkflags>-isysroot <linkflags>${SDK_PATH}
  ;
EOF
