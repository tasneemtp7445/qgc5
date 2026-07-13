# ============================================================================
# QGroundControl CMake Build Configuration
# ============================================================================

cmake_minimum_required(VERSION 3.25)

# ----------------------------------------------------------------------------
# CMake Module Paths
# ----------------------------------------------------------------------------
list(APPEND CMAKE_MODULE_PATH
    "${CMAKE_SOURCE_DIR}/cmake"
    "${CMAKE_SOURCE_DIR}/cmake/find-modules"
    "${CMAKE_SOURCE_DIR}/cmake/install"
    "${CMAKE_SOURCE_DIR}/cmake/install/CPack"
    "${CMAKE_SOURCE_DIR}/cmake/modules"
    "${CMAKE_SOURCE_DIR}/cmake/platform"
)

# Include helper functions early
include(Helpers)

# ----------------------------------------------------------------------------
# Default Build Type
# ----------------------------------------------------------------------------
if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
    set(CMAKE_BUILD_TYPE "Release" CACHE STRING "Build type (Debug or Release)" FORCE)
    message(STATUS "No build type specified. Defaulting to Release.")
endif()

# ----------------------------------------------------------------------------
# CMake Policy Configuration
# ----------------------------------------------------------------------------
set(CMAKE_REQUIRED_QUIET ON)
set(CMAKE_POLICY_VERSION_MINIMUM ${CMAKE_MINIMUM_REQUIRED_VERSION})

# ============================================================================
# Custom Build Configuration
# ============================================================================

# Load default options and allow custom builds to override
include(CustomOptions)

option(QGC_VERBOSE_CONFIGURE "Prefix configure messages with module context labels" OFF)
set(CMAKE_MESSAGE_CONTEXT_SHOW ${QGC_VERBOSE_CONFIGURE})
list(APPEND CMAKE_MESSAGE_CONTEXT qgc)

# build-config.json is the source of truth; keep cmake_minimum_required(...) above in sync.
if(CMAKE_VERSION VERSION_LESS QGC_CONFIG_CMAKE_MINIMUM)
    message(FATAL_ERROR "QGC: requires CMake ${QGC_CONFIG_CMAKE_MINIMUM}+, found ${CMAKE_VERSION}")
endif()

if(IS_DIRECTORY "${CMAKE_SOURCE_DIR}/${QGC_CUSTOM_DIR}")
    message(STATUS "QGC: Custom build directory detected: ${QGC_CUSTOM_DIR}")
    set(QGC_CUSTOM_BUILD ON)
    list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/${QGC_CUSTOM_DIR}/cmake")
    include(CustomOverrides)
endif()

<<<<<<< HEAD
#######################################################
#                   Project Info
#######################################################

# set(CMAKE_OSX_ARCHITECTURES "arm64")
# set(CMAKE_OSX_SYSROOT "iphoneos")
if(APPLE)
    set(CMAKE_OSX_DEPLOYMENT_TARGET "12.0")
=======
# Disable testing if not explicitly enabled
if(NOT QGC_BUILD_TESTING)
    set(BUILD_TESTING OFF CACHE INTERNAL "Disable testing by default" FORCE)
>>>>>>> 76e02ed47cfbb341a780befd7d0dc21db30a5b60
endif()

# ============================================================================
# Project Configuration
# ============================================================================

# ----------------------------------------------------------------------------
# Apple-Specific Pre-Project Settings
# ----------------------------------------------------------------------------
# APPLE is true on iOS too; gate on CMAKE_SYSTEM_NAME or the iOS toolchain's
# arm64-only CMAKE_OSX_ARCHITECTURES gets clobbered with x86_64h;arm64.
if(CMAKE_SYSTEM_NAME STREQUAL "Darwin")
    set(CMAKE_OSX_DEPLOYMENT_TARGET "${QGC_CONFIG_MACOS_DEPLOYMENT_TARGET}" CACHE STRING "macOS minimum deployment target")
    if(QGC_MACOS_UNIVERSAL_BUILD)
        set(CMAKE_OSX_ARCHITECTURES "x86_64h;arm64")
    endif()
endif()

# ----------------------------------------------------------------------------
# Git Integration & Version Extraction
# ----------------------------------------------------------------------------
include(Git)

# ----------------------------------------------------------------------------
# Compiler Caching Configuration
# ----------------------------------------------------------------------------
if(QGC_USE_CACHE)
    qgc_config_caching()
endif()

# ----------------------------------------------------------------------------
# Project Declaration
# ----------------------------------------------------------------------------
project(${QGC_APP_NAME}
    VERSION ${QGC_APP_VERSION}
    DESCRIPTION "${QGC_APP_DESCRIPTION}"
    HOMEPAGE_URL "https://${QGC_ORG_DOMAIN}"
    LANGUAGES C CXX
)

# ============================================================================
# CMake & Build System Configuration
# ============================================================================

# Standard CMake modules
include(GNUInstallDirs)
include(FetchContent)
include(CMakePrintHelpers)
if(QGC_BUILD_TESTING)
    include(CTest)
endif()

# ----------------------------------------------------------------------------
# CPM (CMake Package Manager) Configuration
# ----------------------------------------------------------------------------
if(NOT CPM_SOURCE_CACHE)
    if(DEFINED ENV{CPM_SOURCE_CACHE} AND NOT "$ENV{CPM_SOURCE_CACHE}" STREQUAL "")
        set(CPM_SOURCE_CACHE "$ENV{CPM_SOURCE_CACHE}" CACHE PATH "CPM source cache directory")
    else()
        set(CPM_SOURCE_CACHE "${CMAKE_SOURCE_DIR}/.cache/CPM" CACHE PATH "CPM source cache directory")
    endif()
endif()
include(CPM)
include(CPMTrackHead)

# ----------------------------------------------------------------------------
# Toolchain Configuration (Compiler, Linker, Build Settings)
# ----------------------------------------------------------------------------
include(Toolchain)

# ----------------------------------------------------------------------------
# Python interpreter for code generators (prefer workspace .venv)
# ----------------------------------------------------------------------------
include(PythonVenv)
find_package(Python3 REQUIRED COMPONENTS Interpreter)
include(QGCQmlCodegen)

# ----------------------------------------------------------------------------
# Output Directories
# ----------------------------------------------------------------------------
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/$<CONFIG>/lib")
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/$<CONFIG>")
if(ANDROID)
    set(CMAKE_PDB_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}")
else()
    set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/$<CONFIG>")
endif()

# ----------------------------------------------------------------------------
# CMake Policies
# ----------------------------------------------------------------------------
# CMP0168: Modern FetchContent integration
if(POLICY CMP0168)
    cmake_policy(SET CMP0168 NEW)
    set(CMAKE_POLICY_DEFAULT_CMP0168 NEW)
endif()

# CMP0141: MSVC debug information format
cmake_policy(SET CMP0141 NEW)
set(CMAKE_POLICY_DEFAULT_CMP0141 NEW)

# CMP0075: Include files in CheckIncludeFile
cmake_policy(SET CMP0075 NEW)
set(CMAKE_POLICY_DEFAULT_CMP0075 NEW)

# CMP0194: MSVC is not an assembler for language ASM (zstd)
if(POLICY CMP0194)
    cmake_policy(SET CMP0194 NEW)
    set(CMAKE_POLICY_DEFAULT_CMP0194 NEW)
endif()

# ============================================================================
# Vulkan Headers (needed by Qt on Windows when Vulkan SDK is not installed)
# ============================================================================
if(WIN32 AND NOT TARGET Vulkan::Headers)
    find_package(Vulkan QUIET COMPONENTS Headers)
    if(NOT Vulkan_FOUND)
        CPMAddPackage(
            NAME VulkanHeaders
            GITHUB_REPOSITORY KhronosGroup/Vulkan-Headers
            GIT_TAG vulkan-sdk-1.4.341.0
            SYSTEM YES
        )
        if(VulkanHeaders_SOURCE_DIR)
            set(Vulkan_INCLUDE_DIR "${VulkanHeaders_SOURCE_DIR}/include" CACHE PATH "" FORCE)
        endif()
    endif()
endif()

# ============================================================================
# Qt6 Configuration
# ============================================================================

set(QT_NO_PRIVATE_MODULE_WARNING ON)

find_package(Qt6 ${QGC_QT_MINIMUM_VERSION} QUIET COMPONENTS Core)
if(NOT Qt6_FOUND)
    message(FATAL_ERROR
        "Qt6 ${QGC_QT_MINIMUM_VERSION}+ not found.\n"
        "Set CMAKE_PREFIX_PATH to your Qt installation, e.g.:\n"
        "  cmake -DCMAKE_PREFIX_PATH=~/Qt/6.8.3/gcc_64 ..\n"
        "  (or use qt-cmake which sets this automatically)\n"
        "Searched: ${CMAKE_PREFIX_PATH}"
    )
endif()

find_package(Qt6
    ${QGC_QT_MINIMUM_VERSION}...${QGC_QT_MAXIMUM_VERSION}
    REQUIRED
    COMPONENTS
        Graphs
        Concurrent
        Core
        Gui
        HttpServer
        LinguistTools
        Location
        LocationPrivate
        Multimedia
        Network
        Positioning
        Qml
        QmlIntegration
        Quick
        QuickControls2
        QuickVectorImage
        QuickWidgets
        Sensors
        Sql
        Svg
        TextToSpeech
        Xml
        Quick3D
        StateMachine
    OPTIONAL_COMPONENTS
        Bluetooth
        MultimediaQuickPrivate
        OpenGL
        QuickTest
        SerialPort
        Test
)

if(LINUX AND NOT ANDROID)
    find_package(Qt6 ${QGC_QT_MINIMUM_VERSION}...${QGC_QT_MAXIMUM_VERSION} COMPONENTS WaylandClient)
endif()

qt_standard_project_setup(
    REQUIRES ${QGC_QT_MINIMUM_VERSION}
    SUPPORTS_UP_TO ${QGC_QT_MAXIMUM_VERSION}
    I18N_SOURCE_LANGUAGE en
)

# ----------------------------------------------------------------------------
# Qt Policies (Enable modern Qt6 behaviors)
# ----------------------------------------------------------------------------
qt_policy(
    SET QTP0001 NEW  # Modern resource handling
    SET QTP0002 NEW  # New behavior for QML module URI
    SET QTP0003 NEW  # Better QML type registration
    SET QTP0004 NEW  # Improved translation handling
    SET QTP0005 NEW  # Enhanced deployment handling
)

if(QT_QML_NO_CACHEGEN)
    add_compile_definitions(QT_QML_NO_CACHEGEN)
endif()

# ============================================================================
# Custom Build Subdirectory
# ============================================================================

if(QGC_CUSTOM_BUILD)
    add_subdirectory("${QGC_CUSTOM_DIR}")
endif()

# ============================================================================
# QGroundControl Resources
# ============================================================================

# Resources go on the executable (not a library) to avoid Q_INIT_RESOURCE().
# Don't route the big .qrcs through qt_add_big_resources — its pass2 object-file
# output fails on MSVC ("No data signature found") when large data sections are elided.
list(APPEND QGC_RESOURCES
    "${CMAKE_SOURCE_DIR}/qgcresources.qrc"
)

# ============================================================================
# QGroundControl Executable Target
# ============================================================================

include(Hardening)
qgc_apply_global_hardening()

# Create the main executable
qt_add_executable(${CMAKE_PROJECT_NAME}
    WIN32          # Windows GUI application
    MACOSX_BUNDLE  # macOS application bundle
    ${QGC_RESOURCES}
)

set_target_properties(${CMAKE_PROJECT_NAME} PROPERTIES
    ADDITIONAL_CLEAN_FILES "${CMAKE_BINARY_DIR}/ccache-launcher"
)

# Apply optional sanitizer instrumentation to the main target.
include(Sanitizers)

# Apply optional coverage instrumentation and coverage targets.
include(Coverage)

# Apply compiler warning configuration to QGC target
qgc_apply_warning_flags()

# ----------------------------------------------------------------------------
# Platform-Specific Configuration
# ----------------------------------------------------------------------------
if(WIN32)
    include(Windows)
elseif(APPLE)
    include(Apple)
elseif(ANDROID)
<<<<<<< HEAD
    if(${Qt6_VERSION} VERSION_EQUAL 6.6.3)
        if(NOT ${CMAKE_ANDROID_NDK_VERSION} VERSION_EQUAL 25.1)
            message(FATAL_ERROR "Invalid NDK Version: ${CMAKE_ANDROID_NDK_VERSION}, Use Version 25B instead.")
        endif()
    elseif(${Qt6_VERSION} VERSION_EQUAL 6.8.3)
        if(NOT ${CMAKE_ANDROID_NDK_VERSION} VERSION_EQUAL 26.1)
            message(FATAL_ERROR "Invalid NDK Version: ${CMAKE_ANDROID_NDK_VERSION}, Use Version 26B instead.")
        endif()
    endif()

    # Generation of android version numbers must be consistent release to release such that they are always increasing
    if(${CMAKE_PROJECT_VERSION_MAJOR} GREATER 9)
        message(FATAL_ERROR "Major version larger than 1 digit: ${CMAKE_PROJECT_VERSION_MAJOR}")
    endif()
    if(${CMAKE_PROJECT_VERSION_MINOR} GREATER 9)
        message(FATAL_ERROR "Minor version larger than 1 digit: ${CMAKE_PROJECT_VERSION_MINOR}")
    endif()
    if(${CMAKE_PROJECT_VERSION_PATCH} GREATER 99)
        message(FATAL_ERROR "Patch version larger than 2 digits: ${CMAKE_PROJECT_VERSION_PATCH}")
    endif()

    # Bitness for android version number is 66/34 instead of 64/32 in because of a required version number bump screw-up ages ago
    set(ANDROID_BITNESS_CODE)
    if(${CMAKE_ANDROID_ARCH_ABI} STREQUAL "armeabi-v7a" OR ${CMAKE_ANDROID_ARCH_ABI} STREQUAL "x86")
        set(ANDROID_BITNESS_CODE 34)
    elseif(${CMAKE_ANDROID_ARCH_ABI} STREQUAL "arm64-v8a" OR ${CMAKE_ANDROID_ARCH_ABI} STREQUAL "x86_64")
        set(ANDROID_BITNESS_CODE 66)
    else()
        message(FATAL_ERROR "Unsupported Android ABI: ${CMAKE_ANDROID_ARCH_ABI}")
    endif()

    set(ANDROID_PATCH_VERSION ${CMAKE_PROJECT_VERSION_PATCH})
    if(${CMAKE_PROJECT_VERSION_PATCH} LESS 10)
        set(ANDROID_PATCH_VERSION "0${CMAKE_PROJECT_VERSION_PATCH}")
    endif()

    # Version code format: BBMIPPDDD (B=Bitness, M=Major, I=Minor, P=Patch, D=Dev) - Dev not currently supported and always 000
    set(ANDROID_VERSION_CODE "${ANDROID_BITNESS_CODE}${CMAKE_PROJECT_VERSION_MAJOR}${CMAKE_PROJECT_VERSION_MINOR}${ANDROID_PATCH_VERSION}000")
    message(STATUS "Android version code: ${ANDROID_VERSION_CODE}")

    set_target_properties(${CMAKE_PROJECT_NAME}
        PROPERTIES
            # QT_ANDROID_ABIS ${CMAKE_ANDROID_ARCH_ABI}
            # QT_ANDROID_SDK_BUILD_TOOLS_REVISION
            QT_ANDROID_MIN_SDK_VERSION ${QGC_QT_ANDROID_MIN_SDK_VERSION}
            QT_ANDROID_TARGET_SDK_VERSION ${QGC_QT_ANDROID_TARGET_SDK_VERSION}
            # QT_ANDROID_COMPILE_SDK_VERSION
            QT_ANDROID_PACKAGE_NAME "${QGC_ANDROID_PACKAGE_NAME}"
            QT_ANDROID_PACKAGE_SOURCE_DIR "${QGC_ANDROID_PACKAGE_SOURCE_DIR}"
            QT_ANDROID_VERSION_NAME "${CMAKE_PROJECT_VERSION}"
            QT_ANDROID_VERSION_CODE ${ANDROID_VERSION_CODE}
            # QT_ANDROID_APP_NAME
            # QT_ANDROID_APP_ICON
            # QT_QML_IMPORT_PATH
            QT_QML_ROOT_PATH ${CMAKE_SOURCE_DIR}
            # QT_ANDROID_SYSTEM_LIBS_PREFIX
    )

    # if(CMAKE_BUILD_TYPE STREQUAL "Debug")
    #     set(QT_ANDROID_APPLICATION_ARGUMENTS)
    # endif()

    list(APPEND QT_ANDROID_MULTI_ABI_FORWARD_VARS QGC_STABLE_BUILD QT_HOST_PATH)

    CPMAddPackage(
        NAME android_openssl
        URL https://github.com/KDAB/android_openssl/archive/refs/heads/master.zip
    )
    include(${android_openssl_SOURCE_DIR}/android_openssl.cmake)
    add_android_openssl_libraries(${CMAKE_PROJECT_NAME})
=======
    include(Android)
elseif(LINUX)
    include(Linux)
>>>>>>> 76e02ed47cfbb341a780befd7d0dc21db30a5b60
endif()

# ----------------------------------------------------------------------------
# QML Module Configuration
# ----------------------------------------------------------------------------
qt_add_qml_module(${CMAKE_PROJECT_NAME}
    URI QGC
    VERSION 1.0
    RESOURCE_PREFIX /qml
    IMPORTS
        QtQuick
        QtQuick.Controls
        QtQuick.Dialogs
        QtQuick.Layouts
)

# ----------------------------------------------------------------------------
# Source & Test Subdirectories
# ----------------------------------------------------------------------------
add_subdirectory(src)

if(QGC_BUILD_TESTING)
    add_subdirectory(test)
    # Exclude test directory from translation scanning
    set_property(DIRECTORY test PROPERTY QT_EXCLUDE_FROM_TRANSLATION ON)
endif()

<<<<<<< HEAD
if(QGC_CUSTOM_BUILD)
    find_package(Qt6 REQUIRED COMPONENTS ${CUSTOM_QT_COMPONENTS})
    target_sources(${CMAKE_PROJECT_NAME} PRIVATE ${CUSTOM_SOURCES})
    target_link_libraries(${CMAKE_PROJECT_NAME} PRIVATE ${CUSTOM_LIBRARIES})
    target_include_directories(${CMAKE_PROJECT_NAME} PRIVATE ${CUSTOM_INCLUDE_DIRECTORIES})
=======
# ----------------------------------------------------------------------------
# Translation/Localization Configuration
# ----------------------------------------------------------------------------
file(GLOB TS_SOURCES CONFIGURE_DEPENDS "${CMAKE_SOURCE_DIR}/translations/qgc_*.ts")
# Exclude pseudo-localization files from non-debug builds.
# Multi-config generators (VS, Xcode, Ninja Multi-Config) do not set CMAKE_BUILD_TYPE
# at configure time, so _eo files cannot be conditionally included for Debug only —
# excluding them from all multi-config configurations avoids shipping them in Release.
get_property(_qgc_is_multi_config GLOBAL PROPERTY GENERATOR_IS_MULTI_CONFIG)
if(_qgc_is_multi_config OR NOT CMAKE_BUILD_TYPE STREQUAL "Debug")
    list(FILTER TS_SOURCES EXCLUDE REGEX "_eo\\.ts$")
>>>>>>> 76e02ed47cfbb341a780befd7d0dc21db30a5b60
endif()

set(QT_NO_MISSING_CATALOG_LANGUAGE_WARNING ON)

qt_add_translations(${CMAKE_PROJECT_NAME}
    TS_FILES ${TS_SOURCES}
    RESOURCE_PREFIX "/"
    LUPDATE_OPTIONS -no-obsolete
    TS_FILE_DIR "${CMAKE_SOURCE_DIR}/translations"
    TS_FILE_BASE ${CMAKE_PROJECT_NAME}
    QM_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/i18n"
    MERGE_QT_TRANSLATIONS
)

# ----------------------------------------------------------------------------
# Qt Quick Controls Configuration
# ----------------------------------------------------------------------------
qgc_set_qt_resource_alias("${CMAKE_SOURCE_DIR}/resources/qtquickcontrols2.conf")

qt_add_resources(${CMAKE_PROJECT_NAME} "qgcresources_cmake"
    PREFIX "/"
    FILES "${CMAKE_SOURCE_DIR}/resources/qtquickcontrols2.conf"
)

# ----------------------------------------------------------------------------
# Qt Plugin Configuration
# ----------------------------------------------------------------------------
qt_import_plugins(${CMAKE_PROJECT_NAME}
    INCLUDE Qt6::QSvgPlugin Qt6::QOffscreenIntegrationPlugin
    EXCLUDE_BY_TYPE geoservices  # Use built-in location plugins
    INCLUDE_BY_TYPE sqldrivers Qt6::QSQLiteDriverPlugin
)

<<<<<<< HEAD
if(LINUX)
    qt_import_plugins(${CMAKE_PROJECT_NAME} 
        INCLUDE
            Qt6::QWaylandIntegrationPlugin
            Qt6::QXcbIntegrationPlugin
            Qt6::QEglFSIntegrationPlugin
            Qt6::QWaylandEglPlatformIntegrationPlugin
    )
endif()

=======
# Linux-specific Qt platform plugins
if(LINUX)
    qt_import_plugins(${CMAKE_PROJECT_NAME}
        INCLUDE
            Qt6::QWaylandIntegrationPlugin      # Wayland support (libqwayland.so)
            Qt6::QXcbIntegrationPlugin          # X11 support
            Qt6::QEglFSIntegrationPlugin        # Embedded GL support
    )
endif()

# ============================================================================
# Installation & Packaging
# ============================================================================

>>>>>>> 76e02ed47cfbb341a780befd7d0dc21db30a5b60
include(Install)

# ============================================================================
# Build Summary
# ============================================================================

include(PrintSummary)
