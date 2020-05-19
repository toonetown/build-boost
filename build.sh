#!/bin/bash

cd "$(dirname "${0}")"
BUILD_DIR="$(pwd)"
cd ->/dev/null

# Homebrew bootstrapping information
: ${HB_BOOTSTRAP_GIST_URL:="https://gist.githubusercontent.com/toonetown/48101686e509fda81335/raw"}
HB_BOOTSTRAP="b:boost-build"
HB_BOOTSTRAP_ANDROID="t:*toonetown/android b:android-ndk
                      t:toonetown/extras b:toonetown-extras s:toonetown-extras b:android-env"
HB_BOOTSTRAP_NATIVE="b:dos2unix"

# Overridable build locations
: ${DEFAULT_BOOST_DIST:="${BUILD_DIR}/boost"}
: ${OBJDIR_ROOT:="${BUILD_DIR}/target"}
: ${CONFIGS_DIR:="${BUILD_DIR}/configs"}
: ${B2_BIN:="$(which b2 || echo "${BUILD_DIR}/target/b2")"}

# Packages to bundle
: ${PKG_COMBINED_ARCHS:="windows.i386 windows.x86_64 macosx.x86_64"}

# Options to control the build
: ${BOOST_BUILD_LOG_LEVEL:=1}
: ${BOOST_BUILD_PARALLEL:="$(sysctl -n hw.ncpu)"}
: ${BOOST_BUILD_LAYOUT:="system"}
: ${BOOST_BUILD_LIBS:="--with-filesystem \
                       --with-log define=BOOST_LOG_USE_STD_REGEX \
                       --with-program_options \
                       --with-test \
                       --with-thread"}
: ${BOOST_BUILD_LINK:="static"}
: ${BOOST_BUILD_THREADING:="multi"}
: ${BOOST_BUILD_OPTIONS:="link=${BOOST_BUILD_LINK} threading=${BOOST_BUILD_THREADING}"}

list_arch() {
    if [ -z "${1}" ]; then
        PFIX="${CONFIGS_DIR}/setup-*"
    else
        PFIX="${CONFIGS_DIR}/setup-${1}"
    fi
    ls -m ${PFIX}.*.sh 2>/dev/null | sed "s#${CONFIGS_DIR}/setup-\(.*\)\.sh#\1#" | \
                         tr -d '\n' | \
                         sed -e 's/ \+/ /g' | sed -e 's/^ *\(.*\) *$/\1/g'
}

list_plats() {
    for i in $(list_arch | sed -e 's/,//g'); do
        echo "${i}" | cut -d'.' -f1
    done | sort -u
}

print_usage() {
    while [ $# -gt 0 ]; do
        echo "${1}" >&2
        shift 1
        if [ $# -eq 0 ]; then echo "" >&2; fi
    done
    echo "Usage: ${0} [/path/to/boost-dist] <plat.arch|plat|'bootstrap'|'clean'|'headers'>" >&2
    echo ""                                                                                 >&2
    echo "\"/path/to/boost-dist\" is optional and defaults to:"                             >&2
    echo "    \"${DEFAULT_BOOST_DIST}\""                                                    >&2
    echo ""                                                                                 >&2
    echo "Possible plat.arch combinations are:"                                             >&2
    for p in $(list_plats); do
        echo "    ${p}:"                                                                    >&2
        echo "        $(list_arch ${p})"                                                    >&2
        echo ""                                                                             >&2
    done
    echo "If you specify just a plat, then *all* architectures will be built for that"      >&2
    echo "platform, and the resulting libraries will be \"lipo\"-ed together to a single"   >&2
    echo "fat binary (if supported)."                                                       >&2
    echo ""                                                                                 >&2
    echo "When specifying clean, you may optionally include a plat or plat.arch to clean,"  >&2
    echo "i.e. \"${0} clean macosx.i386\" to clean only the i386 architecture on Mac OS X"  >&2
    echo "or \"${0} clean ios\" to clean all ios builds.  Specifying \"all\" to clean will" >&2
    echo "blindly clean everything in the target directory - including bootstrapped b2."    >&2
    echo ""                                                                                 >&2
    echo "You can specify an optional \"brew\" to bootstrap if you would like to bootstrap" >&2
    echo "a homebrew-based version of boost.build instead of building it locally, i.e. "    >&2
    echo "\"${0} bootstrap brew\".  Note that this requires an active Internet connection." >&2
    echo ""                                                                                 >&2
    echo "You can also specify specify an optional \"android\" to bootstrap in order to"    >&2
    echo "bootstrap the android build environment (uses homebrew), i.e. "                   >&2
    echo "\"${0} bootstrap android\".  Note that this requires an active Internet"          >&2
    echo "connection."                                                                      >&2
    echo ""                                                                                 >&2
    echo "You can copy the windows outputs to non-windows target directory by running"      >&2
    echo "\"${0} copy-windows /path/to/windows/target"                                      >&2
    echo ""                                                                                 >&2
    echo "You can specify to package the release (after it's already been built) by"        >&2
    echo "running \"${0} package /path/to/output"                                           >&2
    echo ""                                                                                 >&2
    return 1
}

do_bootstrap() {
    if [ "${1}" == "brew" ]; then
        curl -sSL "${HB_BOOTSTRAP_GIST_URL}" | /bin/bash -s -- ${HB_BOOTSTRAP}
        return $?
    elif [ "${1}" == "android" ]; then
        curl -sSL "${HB_BOOTSTRAP_GIST_URL}" | /bin/bash -s -- ${HB_BOOTSTRAP_ANDROID}
        return $?
    else
        curl -sSL "${HB_BOOTSTRAP_GIST_URL}" | /bin/bash -s -- ${HB_BOOTSTRAP_NATIVE} || return $?
        if [ -x "${B2_BIN}" ]; then
            echo "B2 already exists at \"${B2_BIN}\""
        else
            echo "Bootstrapping \"${B2_BIN}\"..."
            cd "${PATH_TO_BOOST_DIST}/tools/build/src/engine"
            ./build.sh || { cd ->/dev/null; return 1; }
            cd ->/dev/null
            
            mkdir -p "$(dirname "${B2_BIN}")"
            cp "${PATH_TO_BOOST_DIST}/tools/build/src/engine/b2" "${B2_BIN}" || return $?
        fi
        return 0
    fi
}

get_b2() {
    echo -n "${B2_BIN} -d${BOOST_BUILD_LOG_LEVEL} -j${BOOST_BUILD_PARALLEL} -q"
    echo -n " --layout=${BOOST_BUILD_LAYOUT}"
    echo -n " --hash"
    echo -n " --build-dir=\"${OBJDIR_ROOT}/objdir-${1}\""
    echo -n " --stagedir=\"${OBJDIR_ROOT}/objdir-${1}\""
    echo -n " --includedir=\"${OBJDIR_ROOT}/include\""
    echo -n " ${BOOST_BUILD_LIBS}"
}

do_headers() {
    # Clean here - in case we pass a "clean" command
    if [ "${1}" == "clean" ]; then do_clean headers; return $?; fi

    if [ "${HEADERS_BUILT}" != "yes" ]; then
        cd "${PATH_TO_BOOST_DIST}"
        echo "Building and installing headers..."
        eval "$(get_b2 headers) headers" || { cd ->/dev/null; return 1; }
        cd ->/dev/null
        mkdir -p "${OBJDIR_ROOT}/include" || return $?
        cp -r "${PATH_TO_BOOST_DIST}/boost" "${OBJDIR_ROOT}/include" || return $?
        HEADERS_BUILT="yes"
    else
        echo "Headers are already built"
    fi
}

do_build() {
    TARGET="${1}"; shift
    PLAT="$(echo "${TARGET}" | cut -d'.' -f1)"
    ARCH="$(echo "${TARGET}" | cut -d'.' -f2)"
    CONFIG_SETUP="${CONFIGS_DIR}/setup-${TARGET}.sh"
    
    # Clean here - in case we pass a "clean" command
    if [ "${1}" == "clean" ]; then do_clean ${TARGET}; return $?; fi

    cd "${PATH_TO_BOOST_DIST}"
    
    if [ -f "${CONFIG_SETUP}" -a "${PLAT}" != "${ARCH}" ]; then
        echo "Building architecture '${TARGET}'..."
        
        # Load configuration files
        [ -f "${CONFIGS_DIR}/setup-${PLAT}.sh" ] && {
            source "${CONFIGS_DIR}/setup-${PLAT}.sh"    || return $?
        }
        
        # Generate the project and build
        source "${CONFIG_SETUP}" && \
            source "${GEN_SCRIPT}" && \
            do_headers && \
            eval "$(get_b2 ${TARGET}) ${OPTS} ${BOOST_BUILD_OPTIONS} $@"
    elif [ -n "${TARGET}" -a -n "$(list_arch ${TARGET})" ]; then
        PLATFORM="${TARGET}"

        # Load configuration file for the platform
        [ -f "${CONFIGS_DIR}/setup-${PLATFORM}.sh" ] && {
            source "${CONFIGS_DIR}/setup-${PLATFORM}.sh"    || return $?
        }
        
        if [ -n "${LIPO_PATH}" ]; then
            echo "Building fat binary for platform '${PLATFORM}'..."
        else
            echo "Building all architectures for platform '${PLATFORM}'..."
        fi

        for a in $(list_arch ${PLATFORM} | sed -e 's/,//g'); do
            do_build ${a} || return $?
        done
        
        if [ -n "${LIPO_PATH}" ]; then
            # Set up variables to get our libraries to lipo
            PLATFORM_DIRS="$(find ${OBJDIR_ROOT} -type d -name "objdir-${PLATFORM}.*" -depth 1)"
            PLATFORM_LIBS="$(find ${PLATFORM_DIRS} -type d -name "lib" -depth 1)"
            FAT_OUTPUT="${OBJDIR_ROOT}/objdir-${PLATFORM}/lib"

            mkdir -p "${FAT_OUTPUT}" || return $?
            for l in $(find ${PLATFORM_LIBS} -type f -name '*.a' -exec basename {} \; | sort -u); do
                echo "Running lipo for library '${l}'..."
                ${LIPO_PATH} -create $(find ${PLATFORM_LIBS} -type f -name "${l}") -output "${FAT_OUTPUT}/${l}"
            done
        fi
    else
        print_usage "Missing/invalid target '${TARGET}'"
    fi
    ret=$?
    
    cd ->/dev/null
    return ${ret}
}

do_clean() {
    if [ "${1}" == "all" ]; then
        echo "Cleaning up all builds (including bootstrapped b2) in \"${OBJDIR_ROOT}\"..."
        rm -rf "${OBJDIR_ROOT}"
    elif [ -n "${1}" ]; then
        echo "Cleaning up ${1} builds in \"${OBJDIR_ROOT}\"..."
        rm -rf "${OBJDIR_ROOT}/objdir-${1}" "${OBJDIR_ROOT}/objdir-${1}."*
    else
        echo "Cleaning up all builds in \"${OBJDIR_ROOT}\"..."
        rm -rf "${OBJDIR_ROOT}/objdir-"*  
    fi
    
    # Remove the headers directory if we are cleaning just headers, or everything
    if [ -z "${1}" -o "${1}" == "headers" -o "${1}" == "all" ]; then
        echo "Cleaning up headers in \"${OBJDIR_ROOT}\" and \"${PATH_TO_BOOST_DIST}\"..."
        rm -rf "${OBJDIR_ROOT}/include" "${PATH_TO_BOOST_DIST}/boost"
    fi

    # Remove some leftovers (project-config.jam and an empty OBJDIR_ROOT)
    [ -f "${PATH_TO_BOOST_DIST}/project-config.jam" ] && rm -f "${PATH_TO_BOOST_DIST}/project-config.jam"
    rmdir "${OBJDIR_ROOT}" >/dev/null 2>&1
    return 0
}

do_copy_windows() {
    [ -d "${1}" ] || {
        print_usage "Invalid windows target directory:" "    \"${1}\""
        exit $?
    }
    for WIN_PLAT in $(ls "${1}" | grep 'objdir-windows'); do
        [ -d "${1}/${WIN_PLAT}" -a -d "${1}/${WIN_PLAT}/lib" ] && {
            echo "Copying ${WIN_PLAT}..."
            rm -rf "${OBJDIR_ROOT}/${WIN_PLAT}" || exit $?
            mkdir -p "${OBJDIR_ROOT}/${WIN_PLAT}" || exit $?
            cp -r "${1}/${WIN_PLAT}/lib" "${OBJDIR_ROOT}/${WIN_PLAT}/lib" || exit $?
        } || {
            print_usage "Invalid build target:" "    \"${1}\""
            exit $?
        }
    done
}

do_package() {
    [ -d "${1}" ] || {
        print_usage "Invalid package output directory:" "    \"${1}\""
        exit $?
    }
    
    # Make sure everything exists like it should
    COMBINED_ARCHS="${PKG_COMBINED_ARCHS}"
    [ -n "${COMBINED_ARCHS}" ] || {
      COMBINED_ARCHS="windows.i386 windows.x86_64"
      for p in $(list_plats); do COMBINED_ARCHS="${COMBINED_ARCHS} $(list_arch ${p} | sed -e 's/,//g')"; done
    }
    for a in ${COMBINED_ARCHS}; do
        [ -d "${OBJDIR_ROOT}/objdir-${a}/lib" ] || {
            echo "Architecture ${a} has not been built"
            return 1
        }
    done
	
	  # Fix the include directory headers
	  find "${OBJDIR_ROOT}/include" -type f -exec dos2unix {} \; || return $?
    
    # Build the tarball
    BASE="boost-$(grep '^constant BOOST_VERSION' boost/Jamroot | cut -d':' -f2 | sed -e 's/[ ;]*//g')"
    cp -r "${OBJDIR_ROOT}" "${BASE}" || return $?
    rm -f "${BASE}/b2" || return $?
    rm -rf "${BASE}/objdir-"*/{build,boost} "${BASE}/logs" || return $?
    rm -rf "${BASE}/objdir-headers" || return $?
    rm -rf "${BASE}/objdir-macosx.x86_64" || return $?
    rm -f "${BASE}/objdir-"*"/lib/libboost_atomic"* || return $?
    rm -f "${BASE}/objdir-"*"/lib/libboost_chrono"* || return $?
    rm -f "${BASE}/objdir-"*"/lib/libboost_date_time"* || return $?
    rm -f "${BASE}/objdir-"*"/lib/libboost_system"* || return $?
    find "${BASE}" -name .DS_Store -exec rm {} \; || return $?
    tar -zcvpf "${1}/${BASE}.tar.gz" "${BASE}" || return $?
    rm -rf "${BASE}"
}

# Calculate the path to the boost-dist repository
if [ -d "${1}" ]; then
    cd "${1}"
    PATH_TO_BOOST_DIST="$(pwd)"
    cd ->/dev/null
    shift 1
else
    PATH_TO_BOOST_DIST="${DEFAULT_BOOST_DIST}"
fi

[ -d "${PATH_TO_BOOST_DIST}" -a -f "${PATH_TO_BOOST_DIST}/Jamroot" ] || {
    print_usage "Invalid boost directory:" "    \"${PATH_TO_BOOST_DIST}\""
    exit $?
}

# Call bootstrap if that's what we specified
if [ "${1}" == "bootstrap" ]; then
    do_bootstrap ${2}
    exit $?
fi

# Ensure that B2_BIN is valid
[ -x "${B2_BIN}" ] || {
    print_usage "Could not find b2 executable at '${B2_BIN}'." \
                "Please install (run \"${0} bootstrap\") or set B2_BIN."
    exit $?
}


# Call the appropriate function based on target
TARGET="${1}"; shift
case "${TARGET}" in
    "clean")
        do_clean "$@"
        ;;
    "headers")
        do_headers "$@"
        ;;
    "copy-windows")
        do_copy_windows "$@"
        ;;
    "package")
        do_package "$@"
        ;;
    *)
        do_build ${TARGET} "$@"
        ;;
esac
exit $?
