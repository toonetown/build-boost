## Boost Building ##

This project provides some prebuilt boost configuration scripts for easy building on various platforms.  It contains as a submodule, the [toonetown/boostorg-boost][boostorg-boost] fork of the boost project.  

You can check this directory out in any location on your computer, but the default location that the `build.sh` script looks for is as a parent directory to where you check out the [toonetown/boostorg-boost][boostorg-boost] fork.  By default, this project contains a submodule of the [toonetown/boostorg-boost][boostorg-boost] fork in the correct location.

[boostorg-boost]: https://github.com/toonetown/boostorg-boost

### Requirements ###

These build scripts are meant to be run under most development environments as long as the build tools (Xcode or Visual Studio) are installed.  However, the scripts are tested with the following configurations:

To build on macOS:

 * macOS 10.13 (High Sierra)
 
 * Xcode 9.1 (From Mac App Store)
     * Run Xcode and accept all first-run prompts

To build on Windows:

 * Windows 10
 
 * Visual Studio 2017 (or 2015)
     * Make sure and install `Programming Languages | Visual C++ | Common Tools for Visual C++ 2017` as well
     * If you have both 2017 and 2015 installed, you can select to build for 2015 by setting `SET MSVC_VERSION=14.0` (the default is to use 14.1) prior to running the `build.bat` file.

To build for Android:

 * macOS requirements above
 
 * Android NDK r15c
     * You must set the environment variable `ANDROID_NDK_HOME` to point to your NDK installation


##### Steps (Bootstrap script) #####

The `build.sh` (or `build.bat` on Windows) script accepts a "bootstrap" argument which will build the bjam executable for use in performing the build.  It can be run multiple times safely.

    ./build.sh bootstrap

You can optionally pass "brew" to `build.sh` on macOS to use a prebuilt bjam executable

    ./build.sh bootstrap brew


### Build Steps ###

You can build the Boost project using the `build.sh` script:

    ./build.sh [/path/to/boost-dist] <plat.arch|plat|'bootstrap'|'clean'|'headers'>
    .\build.bat [drive:\path\to\boost-dist] <arch|'all'|'bootstrap'|'clean'|'headers'>

Run `./build.sh` or `.\build.bat` itself to see details on its options.

You can modify the execution of the scripts by setting various environment variables.  See the script sources for lists of these variables.
