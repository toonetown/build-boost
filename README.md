## Boost Building ##

This project provides some prebuilt boost configuration scripts for easy building on various platforms.  It contains as a submodule, the [k9webprotection/boost-releases][boost-releases] fork of the boost project.  

You can check this directory out in any location on your computer, but the default location that the `build.sh` script looks for is as a parent directory to where you check out the [k9webprotection/boost-releases][boost-releases] fork.  By default, this project contains a submodule of the [k9webprotection/boost-releases][boost-releases] fork in the correct location.

[boost-releases]: https://github.com/k9webprotection/boost-releases

### Requirements ###

These build scripts are meant to be run under most development environments as long as the build tools (Xcode or Visual Studio) are installed.  However, the scripts are tested with the following configurations:

To build on OS X:

 * OS X 10.11 (El Capitan)
 
 * Xcode 7.2 (From Mac App Store)
     * Run Xcode and accept all first-run prompts

To build on Windows:

 * Windows 10
 
 * Visual Studio 2015
     * Make sure and install `Programming Languages | Visual C++ | Common Tools for Visual C++ 2015` as well

##### Steps (Bootstrap script) #####

The `build.sh` (or `build.bat` on Windows) script accepts a "bootstrap" argument which will build the bjam executable for use in performing the build.  It can be run multiple times safely.

    ./build.sh bootstrap

You can optionally pass "brew" to `build.sh` on OS X to use a prebuilt bjam executable

    ./build.sh bootstrap brew


### Build Steps ###

You can build the Boost project using the `build.sh` script:

    ./build.sh [/path/to/boost-dist] <plat.arch|plat|'bootstrap'|'clean'|'headers'>
    .\build.bat [drive:\path\to\boost-dist] <arch|'all'|'bootstrap'|'clean'|'headers'>

Run `./build.sh` or `.\build.bat` itself to see details on its options.

You can modify the execution of the scripts by setting various environment variables.  See the script sources for lists of these variables.
