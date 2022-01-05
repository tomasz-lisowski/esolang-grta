include lib/make-pal/pal.mak
DIR_BUILD:=build
DIR_BUILD_LIB:=build-lib
DIR_LIB:=lib
DIR_SOURCE:=src
DIR_INCLUDE:=include
CC:=gcc
CXX:=g++

MAIN_NAME:=grta
MAIN_SRC_WAT:=$(wildcard $(DIR_SOURCE)/*.wat)
MAIN_SRC_C:=$(wildcard $(DIR_SOURCE)/*.c)
MAIN_SRC:= $(MAIN_SRC_WAT) $(MAIN_SRC_C)
MAIN_OBJ:=$(MAIN_SRC_WAT:$(DIR_SOURCE)/%.wat=$(DIR_BUILD)/%.o) $(MAIN_SRC_C:$(DIR_SOURCE)/%.c=$(DIR_BUILD)/%.o)
MAIN_DEP:=$(MAIN_OBJ:%.o=%.d)
MAIN_CC_FLAGS:=-g -W -Wall -Wextra -Wpedantic -Wconversion -Wshadow -I$(DIR_INCLUDE) -Ibuild -I$(DIR_BUILD_LIB)/wabt/wasm2c
MAIN_LD_FLAGS:=

.PHONY: all all-lib main clean clean-lib

all: main

# Calling make again with "-j" means all libs will be built in parallel.
all-lib:
	$(MAKE) -j all-lib-multi
	$(call pal_clrrst)
# This should only be done once at the start or at every submodule update.
all-lib-multi: wabt

main: $(DIR_BUILD) $(DIR_BUILD)/$(MAIN_NAME).$(EXT_BIN)
$(DIR_BUILD)/$(MAIN_NAME).$(EXT_BIN): $(MAIN_OBJ)
	$(CC) $(^) $(DIR_BUILD_LIB)/wabt/wasm2c/wasm-rt-impl.c -o $(@) $(MAIN_CC_FLAGS) $(MAIN_LD_FLAGS)

# Compile source files to object files.
$(DIR_BUILD)/%.wasm: $(DIR_SOURCE)/%.wat
	$(DIR_BUILD_LIB)/wabt/wat2wasm.$(EXT_BIN) $(<) -o $(@)
$(DIR_BUILD)/%.c: $(DIR_BUILD)/%.wasm
	$(DIR_BUILD_LIB)/wabt/wasm2c.$(EXT_BIN) $(<) -o $(@)
$(DIR_BUILD)/%.o: $(DIR_BUILD)/%.c
	$(CC) $(<) -o $(@) $(MAIN_CC_FLAGS) -c -MMD
$(DIR_BUILD)/%.o: $(DIR_SOURCE)/%.c
	$(CC) $(<) -o $(@) $(MAIN_CC_FLAGS) -c -MMD

# Make sure to recompile source files after a header they include changes.
-include $(MAIN_DEP)

# Build wabt.
wabt: $(DIR_BUILD_LIB)
	$(call pal_mkdir,$(DIR_LIB)/wabt/build)
	cd $(DIR_LIB)/wabt/build && cmake -G "$(CMAKE_GENERATOR)" -DCMAKE_C_COMPILER=$(CC) -DCMAKE_CXX_COMPILER=$(CXX) -DCMAKE_MAKE_PROGRAM=$(MAKE) ..
	cd $(DIR_LIB)/wabt/build && $(MAKE) wat2wasm
	cd $(DIR_LIB)/wabt/build && $(MAKE) wasm2c
	$(call pal_mkdir,$(DIR_BUILD_LIB)/wabt)
	$(call pal_mkdir,$(DIR_BUILD_LIB)/wabt/wasm2c)
	$(call pal_cp,$(DIR_LIB)/wabt/build/libwabt.a,$(DIR_BUILD_LIB)/wabt)
ifeq ($(OS),Windows_NT)
	$(call pal_cp,$(DIR_LIB)/wabt/build/wasm2c.exe,$(DIR_BUILD_LIB)/wabt/wasm2c.$(EXT_BIN))
	$(call pal_cp,$(DIR_LIB)/wabt/build/wat2wasm.exe,$(DIR_BUILD_LIB)/wabt/wat2wasm.$(EXT_BIN))
else
	$(call pal_cp,$(DIR_LIB)/wabt/build/wasm2c,$(DIR_BUILD_LIB)/wabt/wasm2c.$(EXT_BIN))
	$(call pal_cp,$(DIR_LIB)/wabt/build/wat2wasm,$(DIR_BUILD_LIB)/wabt/wat2wasm.$(EXT_BIN))
endif
	$(call pal_cpdir,$(DIR_LIB)/wabt/wasm2c,$(DIR_BUILD_LIB)/wabt/wasm2c)

$(DIR_BUILD) $(DIR_BUILD_LIB):
	$(call pal_mkdir,$(@))
clean:
	$(call pal_rmdir,$(DIR_BUILD))
clean-lib:
	$(call pal_rmdir,$(DIR_LIB)/wabt/build)
	$(call pal_rmdir,$(DIR_LIB)/wabt/bin)
	$(call pal_rmdir,$(DIR_BUILD_LIB))
