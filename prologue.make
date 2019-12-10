#
# Detect the build host and target <platform, architecture>.
# By default, the build is performed for host <platform, architecture>
# Android is cross compiled and for that, the $(MAKE) command should be invoked
# with TARGET_OS=android  and TARGET_ARCH=<32,64>
#

#
# Establish OS and CMake Generator
#

_ECHO=echo

ifeq ($(OS),Windows_NT)
	_ECHO = powershell -Command Write-Host
	TARGET_OS ?= windows
	DIR_STUB=${TARGET_OS}

	ifeq (,$(filter AMD64,$(PROCESSOR_ARCHITECTURE)$(PROCESSOR_ARCHITEW6432)))
	    TARGET_ARCH ?= 64
		ARX_CMAKE_GENERATOR := "Visual Studio 15 2017 Win64"
	else
	    TARGET_ARCH ?= 32
		ARX_CMAKE_GENERATOR := "Visual Studio 15 2017"
	endif
else
	LONG_BIT := $(shell getconf LONG_BIT)

	OS_RELEASE_PATH=/etc/os-release
	ifeq ("$(wildcard $(OS_RELEASE_PATH))","")
		TARGET_OS ?= $(shell uname | tr A-Z a-z)
		DIR_STUB=${TARGET_OS}
	else
		VERSION_NAME=$(shell cat $(OS_RELEASE_PATH) | grep -iw id | cut -d= -f 2)
		VERSION_ID=$(shell cat $(OS_RELEASE_PATH) | grep -iw version_id | cut -d= -f 2)
		TARGET_OS=linux
		DIR_STUB=${VERSION_NAME}_${VERSION_ID}
	endif

	TARGET_ARCH ?= $(LONG_BIT)
	ifeq ($(TARGET_OS)$(HGEN),darwinxcode)
		ARX_CMAKE_GENERATOR := "Xcode"
	else
		ARX_CMAKE_GENERATOR := "Unix Makefiles"
	endif
endif

BUILD_TYPE ?= Debug

# Validate the requested architecture.
# We supported building only 64 bit for iOS/OSX.
# For all other platform, we additionally support 32 bit.
# Any other architecture is rejected.
#

ifeq (,$(filter 32 64,$(TARGET_ARCH)))
print_err_msg:
	@$(_ECHO) "Not possible to build for Target_ARCH $(TARGET_ARCH) bit."
endif

ifneq (,$(filter ios darwin,$(TARGET_OS)))
	TARGET_ARCH = 64
endif

#
# Setup build and install directories.
# The builds occur out of source for *NIX platforms,
# inside _builds/<PLATFORM>_<ARCHITECTURE>
# The artifacts are installed to _install/<PLATFORM>_<ARCHITECTURE>
#

ifeq (${TARGET_OS},darwin)
ifneq (${TARGET_ARCH},64)
print_err_msg:
	@$(_ECHO) "Cannot build for ${TARGET_OS} ${TARGET_ARCH} bits."
endif
else ifeq (${TARGET_OS},ios)
ifneq (${TARGET_ARCH},64)
print_err_msg:
	@$(_ECHO) "Cannot build for ${TARGET_OS} ${TARGET_ARCH} bits."
endif
else ifeq (${TARGET_OS},linux)
ifeq (,$(filter 32 64,$(TARGET_ARCH)))
print_err_msg:
	@$(_ECHO) "Cannot build for ${TARGET_OS} ${TARGET_ARCH} bits."
endif
else ifeq (${TARGET_OS},alpine)
ifeq (,$(filter 32 64,$(TARGET_ARCH)))
print_err_msg:
	@$(_ECHO) "Cannot build for ${TARGET_OS} ${TARGET_ARCH} bits."
endif
else ifeq (${TARGET_OS},android)
ifeq (,$(filter 32 64,$(TARGET_ARCH)))
print_err_msg:
	@$(_ECHO) "Cannot build for ${TARGET_OS} ${TARGET_ARCH} bits."
endif
else ifeq (${TARGET_OS},windows)
ifeq (,$(filter 32 64,$(TARGET_ARCH)))
print_err_msg:
	@$(_ECHO) "Cannot build for ${TARGET_OS} ${TARGET_ARCH} bits."
endif
else
print_err_msg:
	@$(_ECHO) "Cannot build for ${TARGET_OS} ${TARGET_ARCH} bits."

endif

_TARGET_OS = ${DIR_STUB}_${TARGET_ARCH}

BUILD_DIR = $(CURDIR)/_builds/$(_TARGET_OS)/$(BUILD_TYPE)
TEST_LOG_DIR = $(CURDIR)/test_logs/$(_TARGET_OS)/$(BUILD_TYPE)

#
# Aggregate options used in CMake into single entity.
#
VERBOSE ?= OFF
ifeq (${VERBOSE},ON)
CMAKE_COMPILE_OPTIONS += -DCMAKE_VERBOSE_MAKEFILE=ON
endif

CMAKE_COMPILE_OPTIONS += -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
ifeq (${TARGET_OS},alpine)
TARGET_CMAKE_EXPORTS += -DTARGET_OS=linux
else
TARGET_CMAKE_EXPORTS += -DTARGET_OS=$(TARGET_OS)
endif
TARGET_CMAKE_EXPORTS += -DTARGET_ARCH=$(TARGET_ARCH)
CMAKE_COMPILE_OPTIONS += -DCMAKE_INSTALL_MESSAGE=NEVER
CMAKE_COMPILE_OPTIONS += -G$(ARX_CMAKE_GENERATOR)
CMAKE_COMPILE_OPTIONS += -DCMAKE_C_STANDARD=11
CMAKE_COMPILE_OPTIONS += -DCMAKE_CXX_STANDARD=11
ifeq (${TARGET_OS},windows)
HCONFIG_BUILD_TYPE += --config $(BUILD_TYPE)
else
CMAKE_COMPILE_OPTIONS += -DCMAKE_BUILD_TYPE=$(BUILD_TYPE)
endif

#
# If all sanitizations are requested, enable them all.
# As of now, it will work only for code compiled with CMake
# and while compiling using CLang or GNU toolchains.
#
ifdef ALL_SAN
	CMAKE_COMPILE_OPTIONS += -DADDRESS_SANITIZER=ON
	CMAKE_COMPILE_OPTIONS += -DUB_SANITIZER=ON
	CMAKE_COMPILE_OPTIONS += -DTHREAD_SANITIZER=ON
	CMAKE_COMPILE_OPTIONS += -DMEMORY_SANITIZER=ON
endif

ifdef ASAN
	CMAKE_COMPILE_OPTIONS += -DADDRESS_SANITIZER=ON
endif

#
# Setup common variables for android cross compile builds. Android NDK supports
# CMake build system to certain extent. We use the NDK along with standalone
# toolchain created using NDK.
#
# The standalone toolchain has to be setup prior to using this make file, using
# the below command:
#	${ANDROID_NDK}/build/tools/make-standalone-toolchain.sh --install-dir=${ANDROID_TOOLCHAIN_PATH}
#
# Android NDK installation path can be provided using ANDROID_NDK_HOME make
# variable. If it is not provided, this makefile assumes existence of NDK at
# /usr/local/share/android-ndk. Similarly, standalone toolchain used to build
# can be controlled using ANDROID_TOOLCHAIN_PATH make variable. If it is not
# provided, /opt/android/toolchain is assumed.
#
# Developer used Android NDK Version 19.0.5232133 on OSX 10.14.4 Beta (18E215a)
# But any recent version of NDK should be working fine.
#
ifeq ($(TARGET_OS),android)
	ANDROID_NDK_HOME ?= /opt/android/android-ndk-r19c/
	ANDROID_TOOLCHAIN_PATH ?= /opt/android/toolchain/

	ANDROID_CMAKE_OPTS += -DCMAKE_TOOLCHAIN_FILE=$(ANDROID_NDK_HOME)/build/cmake/android.toolchain.cmake
	ANDROID_CMAKE_OPTS += -DCMAKE_SYSTEM_NAME="Android"
	ANDROID_CMAKE_OPTS += -DANDROID_PLATFORM="android-23"
	ANDROID_CMAKE_OPTS += -DANDROID_NDK=$(ANDROID_NDK_HOME)
	ANDROID_CMAKE_OPTS += -DANDROID_TOOLCHAIN=clang
	ANDROID_CMAKE_OPTS += -DCMAKE_POSITION_INDEPENDENT_CODE=ON
ifeq ($(TARGET_ARCH),32)
	ANDROID_CMAKE_OPTS += -DANDROID_ABI=armeabi-v7a
	ANDROID_CMAKE_OPTS += -DANDROID_ARM_MODE=arm
else
	ANDROID_CMAKE_OPTS += -DANDROID_ABI=arm64-v8a
endif
else ifeq ($(TARGET_OS),ios)
	IOS_CMAKE_OPTIONS += -DCMAKE_TOOLCHAIN_FILE=$(CURDIR)/cmake/Toolchain-iOS.cmake
endif

#
# 1) Cross compiling wolfssl requires WOLFSSL_HOST variable to be set to
#    corresponding target compiler triple.
# 2) Android CMake requires ABI and ARM mode.
# 3) Wolf uses autoconf, which requires exporting compiler options for cross
#    compilation. Below are few such exports and in future, other appropriate
#    utilities as required should be exported.
#
# The following set's these three properties for the build.
#

ifeq ($(TARGET_OS)$(TARGET_ARCH),android32)
	WOLFSSL_CMAKE_OPTIONS += -DWOLFSSL_HOST=arm-linux-androideabi
	WOLFSSL_CMAKE_OPTIONS += $(ANDROID_CMAKE_OPTS)
	WOLFSSL_CMAKE_OPTIONS += -DARCH=ARM

	export CC=$(ANDROID_TOOLCHAIN_PATH)/bin/arm-linux-androideabi-gcc
	export AR=$(ANDROID_TOOLCHAIN_PATH)/bin/arm-linux-androideabi-ar
	export LINK=$(ANDROID_TOOLCHAIN_PATH)/bin/arm-linux-androideabi-link
	export STRIP=$(ANDROID_TOOLCHAIN_PATH)/bin/arm-linux-androideabi-strip
	export RANLIB=$(ANDROID_TOOLCHAIN_PATH)/bin/arm-linux-androideabi-ranlib
	export DUMPBIN=$(ANDROID_TOOLCHAIN_PATH)/bin/arm-linux-androideabi-dumpbin
	export OBJDUMP=$(ANDROID_TOOLCHAIN_PATH)/bin/arm-linux-androideabi-objdump
else ifeq ($(TARGET_OS)$(TARGET_ARCH),android64)
	WOLFSSL_CMAKE_OPTIONS += -DWOLFSSL_HOST=aarch64-linux-android
	WOLFSSL_CMAKE_OPTIONS += $(ANDROID_CMAKE_OPTS)
	WOLFSSL_CMAKE_OPTIONS += -DARCH=ARM64

	export CC=$(ANDROID_TOOLCHAIN_PATH)/bin/aarch64-linux-android21-clang
	export AR=$(ANDROID_TOOLCHAIN_PATH)/bin/aarch64-linux-android-ar
	export LINK=$(ANDROID_TOOLCHAIN_PATH)/bin/aarch64-linux-android-link
	export STRIP=$(ANDROID_TOOLCHAIN_PATH)/bin/aarch64-linux-android-strip
	export RANLIB=$(ANDROID_TOOLCHAIN_PATH)/bin/aarch64-linux-android-ranlib
	export DUMPBIN=$(ANDROID_TOOLCHAIN_PATH)/bin/aarch64-linux-android-dumpbin
	export OBJDUMP=$(ANDROID_TOOLCHAIN_PATH)/bin/aarch64-linux-android-objdump
else ifeq ($(TARGET_OS),ios)
	WOLFSSL_CMAKE_OPTIONS += -DARCH=ARM64
endif

#
# Compiling SIDH asm modules for darwin doesnt work. Need to be fixed.
# Disabled temporarily.
#
ifneq ($(TARGET_OS),darwin)
ifeq ($(TARGET_ARCH),64)
	CMAKE_COMPILE_OPTIONS += -DOPT_LEVEL=FAST
endif
endif

ifeq (,$(filter $(TARGET_OS),ios android))
	CTEST_CMD=ctest -C $(BUILD_TYPE)
	CTEST_TYPE=-L UnitTest
else
	CTEST_CMD=ls
endif

CMAKE_COMPILE_OPTIONS += $(ANDROID_CMAKE_OPTS) $(IOS_CMAKE_OPTIONS) -Wno-dev

ifeq ("$(TARGET_OS)","windows")
define do_delete
		cmd /c if exist $(subst /,\,$(1)) cmd /c rmdir /Q /S $(subst /,\,$(1))
endef
else
define do_delete
		rm -rf $(1)
endef
endif

# sqlcipher, depends on openssl.
# No openssl for windows and alpine yet.

HAS_SQLCIPHER = yes

ifeq (${TARGET_OS},windows)
HAS_SQLCIPHER = no
else

ALPINE_RELEASE_PATH=/etc/alpine-release
ifneq ("$(wildcard $(ALPINE_RELEASE_PATH))","")
HAS_SQLCIPHER = no
endif
endif
