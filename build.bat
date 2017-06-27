@ECHO OFF &SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

SET BUILD_DIR=%~dp0
SET SCRIPT_NAME=%~0

:: Overridable build locations
IF "%DEFAULT_BOOST_DIST%"=="" SET DEFAULT_BOOST_DIST=%BUILD_DIR%\boost
IF "%BOOST_OBJDIR_ROOT%"=="" SET BOOST_OBJDIR_ROOT=%BUILD_DIR%\target
IF "%CONFIGS_DIR%"=="" SET CONFIGS_DIR=%BUILD_DIR%\configs
IF "%BJAM_BIN%"=="" SET BJAM_BIN=%BUILD_DIR%\target\bjam.exe

:: Options to control the build
IF "%BOOST_BUILD_TOOLSET%"=="" (
  SET BOOST_BUILD_TOOLSET=msvc
  SET BOOST_BUILD_PLATFORM_NAME=windows
) ELSE (
  SET BOOST_BUILD_PLATFORM_NAME=windows-%BOOST_BUILD_TOOLSET%
)
IF "%BOOST_BUILD_LOG_LEVEL%"=="" SET BOOST_BUILD_LOG_LEVEL=1
IF "%BOOST_BUILD_PARALLEL%"=="" SET BOOST_BUILD_PARALLEL=%NUMBER_OF_PROCESSORS%
IF "%BOOST_BUILD_LAYOUT%"=="" SET BOOST_BUILD_LAYOUT=tagged
IF "%BOOST_BUILD_SKIPPED_LIBS%"=="" SET BOOST_BUILD_SKIPPED_LIBS=--without-mpi --without-graph_parallel --without-python
IF "%BOOST_BUILD_LINK%"=="" SET BOOST_BUILD_LINK=static
IF "%BOOST_BUILD_RUNTIME_LINK%"=="" SET BOOST_BUILD_RUNTIME_LINK=static
IF "%BOOST_BUILD_THREADING%"=="" SET BOOST_BUILD_THREADING=multi
IF "%BOOST_BUILD_OPTIMIZATION%"=="" SET BOOST_BUILD_OPTIMIZATION=space
IF "%BOOST_BUILD_INLINING%"=="" SET BOOST_BUILD_INLINING=on
IF "%BOOST_BUILD_OPTIONS%"=="" SET BOOST_BUILD_OPTIONS=link=%BOOST_BUILD_LINK% ^
                                                       runtime-link=%BOOST_BUILD_RUNTIME_LINK% ^
                                                       threading=%BOOST_BUILD_THREADING% ^
                                                       optimization=%BOOST_BUILD_OPTIMIZATION% ^
                                                       inlining=%BOOST_BUILD_INLINING%

:: Calculate the path to the boost-dist repository
IF EXIST "%~f1" (
	SET PATH_TO_BOOST_DIST=%~f1
	SHIFT
) ELSE (
	SET PATH_TO_BOOST_DIST=%DEFAULT_BOOST_DIST%
)

IF NOT EXIST "%PATH_TO_BOOST_DIST%\Jamroot" (
    echo Invalid boost directory: 1>&2
    echo     "%PATH_TO_BOOST_DIST%" 1>&2
    GOTO print_usage
)

:: Call bootstrap if that's what we specified
IF "%~1"=="bootstrap" (
    CALL :do_bootstrap & exit /B %ERRORLEVEL%
)

:: Ensure that BJAM_BIN is valid
IF NOT EXIST "%BJAM_BIN%" (
    echo Could not find bjam executable at "%BJAM_BIN%". 1>&2
    echo Please install (run "%SCRIPT_NAME% bootstrap) or set BJAM_BIN" 1>&2
    echo. 1>&2
    GOTO print_usage
)

:: Set up the target and the command-line arguments
SET TARGET=%1
SHIFT
:GetArgs
IF "%~1" NEQ "" (
    SET CL_ARGS=%CL_ARGS% %1
    SHIFT
    GOTO GetArgs
)
IF DEFINED CL_ARGS SET CL_ARGS=%CL_ARGS:~1%

:: Call the appropriate function based on target
IF "%TARGET%"=="clean" (
    CALL :do_clean %CL_ARGS% || exit /B 1
) ELSE IF "%TARGET%"=="headers" (
    CALL :do_headers %CL_ARGS% || exit /B 1
) ELSE (
    CALL :do_build %TARGET% %CL_ARGS% || exit /B 1
)
:: Success
exit /B 0


:print_usage
    echo Usage: %SCRIPT_NAME% /path/to/boost-dist ^<arch^|'bootstrap'^|'clean'^|'headers'^> 1>&2
    echo. 1>&2
    echo "/path/to/boost-dist" is optional and defaults to: 1>&2
    echo     "%DEFAULT_BOOST_DIST%" 1>&2
    echo. 1>&2
    CALL :get_archs
    echo Possible architectures are:
    echo     !ARCHS: =, ! 1>&2
    echo. 1>&2
    echo When specifying clean, you may optionally include an arch to clean, 1>&2
    echo i.e. "%SCRIPT_NAME% clean i386" to clean only the i386 architecture. 1>&2
    echo Specifying "all" to clean will blindly clean everything in the 1>&2
    echo target directory - including bootstrapped bjam.exe. 1>&2
    echo. 1>&2
@exit /B 1

:get_archs
    @ECHO OFF
    SET ARCHS=
    FOR %%F IN ("%CONFIGS_DIR%\setup-windows.*.bat") DO (
        SET ARCH=%%~nF
        SET ARCHS=!ARCHS! !ARCH:setup-windows.=!
    )
    IF DEFINED ARCHS SET ARCHS=%ARCHS:~1%
@exit /B 0

:do_bootstrap
    @ECHO OFF
    IF NOT EXIST "%BJAM_BIN%" (
        echo Bootstrapping "%BJAM_BIN%"...
        PUSHD "%PATH_TO_BOOST_DIST%\tools\build\src\engine"
        CALL build.bat || (
            POPD & exit /B 1
        )
        POPD
        
        FOR /f "delims=" %%F in ("%BJAM_BIN%") DO @mkdir "%%~dpF" 2>NUL
        copy "%PATH_TO_BOOST_DIST%\tools\build\src\engine\bin.ntx86\bjam.exe" "%BJAM_BIN%" || exit /B 1
        rmdir /Q /S "%PATH_TO_BOOST_DIST%\tools\build\src\engine\bootstrap" 2>NUL
        rmdir /Q /S "%PATH_TO_BOOST_DIST%\tools\build\src\engine\bin.ntx86" 2>NUL        
    ) else (
        echo Bjam already exists at "%BJAM_BIN%"
    )
@exit /B 0

:get_bjam
    @ECHO OFF
    SET BJAM="%BJAM_BIN%" -d%BOOST_BUILD_LOG_LEVEL% -j%BOOST_BUILD_PARALLEL% -q
    SET BJAM=%BJAM% --layout=%BOOST_BUILD_LAYOUT%
    SET BJAM=%BJAM% --abbreviate-paths
    SET BJAM=%BJAM% --build-dir="%BOOST_OBJDIR_ROOT%\objdir-%~1"
    SET BJAM=%BJAM% --stagedir="%BOOST_OBJDIR_ROOT%\objdir-%~1"
    SET BJAM=%BJAM% --includedir="%BOOST_OBJDIR_ROOT%\include"
    SET BJAM=%BJAM% %BOOST_BUILD_SKIPPED_LIBS%
    SET BJAM=%BJAM% toolset=%BOOST_BUILD_TOOLSET%
@exit /B 0

:do_headers
    @ECHO OFF
    :: Clean here - in case we pass a "clean" command
    IF "%~1"=="clean" (
        CALL :do_clean headers & exit /B %ERRORLEVEL%
    )
    
    IF "!HEADERS_BUILT!"=="yes" (
        echo Headers are already built
    ) ELSE (
        PUSHD "%PATH_TO_BOOST_DIST%"
        echo Building and installing headers...

        CALL :get_bjam headers || (
            POPD & exit /B 1
        )
        !BJAM! headers || (
            POPD & exit /B 1
        )
        !BJAM! install-proper-headers || (
            POPD & exit /B 1
        )
        POPD
        SET HEADERS_BUILT=yes
    )
@exit /B 0

:do_build
    @ECHO OFF
    SET CONFIG_SETUP=%CONFIGS_DIR%\setup-windows.%~1.bat
    
    :: Clean here - in case we pass a "clean" command
    IF "%~2"=="clean" (
        CALL :do_clean %~1
        exit /B %ERRORLEVEL%
    )

    IF EXIST "%CONFIG_SETUP%" (
        echo Building architecture "%~1"...
    
        :: Load configuration files
        IF EXIST "%CONFIGS_DIR%\setup-windows.bat" (
            CALL "%CONFIGS_DIR%\setup-windows.bat" || exit /B 1
        )
        
        :: Generate the project and build
        PUSHD "%PATH_TO_BOOST_DIST%"
        CALL "%CONFIG_SETUP%" || (
            POPD & exit /B 1
        )
        CALL :do_headers || (
            POPD & exit /B 1
        )
        CALL :get_bjam %BOOST_BUILD_PLATFORM_NAME%.%~1 || (
            POPD & exit /B 1
        )
        
        !BJAM! !OPTS! !BOOST_BUILD_OPTIONS! || (
            POPD & exit /B 1
        )
        POPD
    ) ELSE (
        echo Missing/invalid target "%~1" 1>&2
        GOTO print_usage
    )
@exit /B 0

:do_clean
    @ECHO OFF
    SET CLEAN_HEADERS=no
    IF "%~1"=="all" (
        echo Cleaning up all builds (including bootstrapped bjam) in "%BOOST_OBJDIR_ROOT%"...
        rmdir /Q /S "%BOOST_OBJDIR_ROOT%" 2>NUL
        SET CLEAN_HEADERS=yes
    ) ELSE IF "%~1"=="" (
        echo Cleaning up all builds in "%BOOST_OBJDIR_ROOT%"...
        FOR /D %%D IN ("%BOOST_OBJDIR_ROOT%\objdir-*") DO rmdir /Q /S "%%D" 2>NUL
        SET CLEAN_HEADERS=yes
    ) ELSE (
        echo Cleaning up %~1 builds in "%BOOST_OBJDIR_ROOT%"...
        rmdir /Q /S "%BOOST_OBJDIR_ROOT%\objdir-%~1" 2>NUL
        rmdir /Q /S "%BOOST_OBJDIR_ROOT%\objdir-%BOOST_BUILD_PLATFORM_NAME%.%~1" 2>NUL
        IF "%~1"=="headers" SET CLEAN_HEADERS=yes
    )

    :: Remove the headers directory if we are cleaning just headers, or everything
    IF "%CLEAN_HEADERS%"=="yes" (
        echo Cleaning up headers in "%BOOST_OBJDIR_ROOT%" and "%PATH_TO_BOOST_DIST%"...
        rmdir /Q /S "%PATH_TO_BOOST_DIST%\boost" 2>NUL
        rmdir /Q /S "%BOOST_OBJDIR_ROOT%\include" 2>NUL
    )

    :: Remove some leftovers
    rmdir /Q "%BOOST_OBJDIR_ROOT%" 2>NUL
@exit /B 0
