.PHONY: all install test build config clean


BUILD_TYPE ?= Release
BUILD_DIR = $(CURDIR)/_build
INSTL_DIR = $(CURDIR)/_install

CMAKE_OPTIONS = -H$(CURDIR)
CMAKE_OPTIONS+= -B$(BUILD_DIR)
CMAKE_OPTIONS+= -DCMAKE_INSTALL_PREFIX=$(INSTL_DIR)
CMAKE_OPTIONS+= -DCMAKE_BUILD_TYPE=$(BUILD_TYPE)
CMAKE_OPTIONS+= $(EXTRA_CMAKE_OPTIONS)

all: install

install: test
	cmake --build $(BUILD_DIR) --target install

test: build
	cmake --build $(BUILD_DIR) --target test

build: config
	cmake --build $(BUILD_DIR)

config:
	cmake ${CMAKE_OPTIONS}

clean:
	rm -rf $(BUILD_DIR) $(INSTL_DIR)