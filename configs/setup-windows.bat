@echo off
SET MIN_WIN_NT_VERSION=0x0601
SET OPTS=architecture=x86 define=WINVER=%MIN_WIN_NT_VERSION% ^
                          define=_WIN32_WINNT=%MIN_WIN_NT_VERSION% ^
                          define=BOOST_LOG_USE_COMPILER_TLS ^
                          define=_SILENCE_ALL_CXX17_DEPRECATION_WARNINGS ^
                          cxxflags=/std:c++17
exit /B 0
