@echo off
SET MIN_WIN_NT_VERSION=0x0601
IF "%CXX_VERSION%"=="" SET CXX_VERSION=17
SET CXX_OPTS=
IF "%CXX_VERSION%"=="17" SET CXX_OPTS=define=_SILENCE_ALL_CXX17_DEPRECATION_WARNINGS ^
                                      cxxflags=/std:c++17
SET OPTS=architecture=x86 define=WINVER=%MIN_WIN_NT_VERSION% ^
                          define=_WIN32_WINNT=%MIN_WIN_NT_VERSION% ^
                          define=BOOST_LOG_USE_COMPILER_TLS ^
                          %CXX_OPTS%
exit /B 0
