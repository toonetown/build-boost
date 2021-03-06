@echo off
IF "%MIN_WIN_NT_VERSION%"=="" SET MIN_WIN_NT_VERSION=0x0A00
IF "%CXX_VERSION%"=="" SET CXX_VERSION=17
SET CXX_OPTS=
IF "%CXX_VERSION%"=="17" SET CXX_OPTS=define=_SILENCE_ALL_CXX17_DEPRECATION_WARNINGS
SET OPTS=architecture=x86 define=WINVER=%MIN_WIN_NT_VERSION% ^
                          define=_WIN32_WINNT=%MIN_WIN_NT_VERSION% ^
                          define=BOOST_LOG_USE_COMPILER_TLS ^
                          cxxstd=%CXX_VERSION% %CXX_OPTS%
exit /B 0
