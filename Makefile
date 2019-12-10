include prologue.make

INSTL_DIR = $(CURDIR)/_install/$(_TARGET_OS)/$(BUILD_TYPE)

all: hw_install

####################################################################################################
# helloworld
####################################################################################################
HW_CMAKE_OPTIONS += -H$(CURDIR)
HW_CMAKE_OPTIONS += -B$(BUILD_DIR)/hw
HW_CMAKE_OPTIONS += $(CMAKE_COMPILE_OPTIONS)
HW_CMAKE_OPTIONS += $(TARGET_CMAKE_EXPORTS)
HW_CMAKE_OPTIONS += -DCMAKE_INSTALL_PREFIX=$(INSTL_DIR)/hw

hw_clean:
	$(call do_delete,$(BUILD_DIR)/hw)
	$(call do_delete,$(INSTL_DIR)/hw)

hw_profile:
	cd $(BUILD_DIR)/hw && $(CTEST_CMD) -L Profiling

hw_install: hw_test
	cmake --build $(BUILD_DIR)/hw --target install $(HCONFIG_BUILD_TYPE)

ifeq (,$(filter $(TARGET_OS),ios android))
hw_test: hw_build
	cd $(BUILD_DIR)/hw && $(CTEST_CMD) $(CTEST_TYPE)
	@$(_ECHO) " "
	@$(_ECHO) "####################################################################################################"
	@$(_ECHO) " Test results are available at $(BUILD_DIR)/hw/Testing/Temporary/LastTest.log"
	@$(_ECHO) "####################################################################################################"
	@$(_ECHO) " "

else
hw_test: hw_build
endif

hw_build: hw_cmake
	cmake --build $(BUILD_DIR)/hw $(HCONFIG_BUILD_TYPE)

hw_cmake:
	@$(_ECHO) "DIR_STUB = ${DIR_STUB}"
	@$(_ECHO) "TARGET_ARCH = ${TARGET_ARCH}"
	cmake $(HW_CMAKE_OPTIONS)

####################################################################################################
# Platform specific clean
####################################################################################################
clean:
	$(call do_delete,$(BUILD_DIR))
	$(call do_delete,$(INSTL_DIR))

clean_all:
	$(call do_delete,_builds)
	$(call do_delete,_install)

####################################################################################################
# Print help
####################################################################################################
help:
	@$(_ECHO) "See readme-building.txt"
