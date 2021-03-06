##############
#
# Esp8266 Architecture build environment
#
##############

ifndef ESP_HOME
$(error ESP_HOME variable is not set to a valid directory.)
endif

## ESP_HOME sets the path where ESP tools and SDK are located.
## Windows:
# ESP_HOME = c:/Espressif

## MacOS / Linux:
# ESP_HOME = /opt/esp-open-sdk

#ifeq ($(OS),Windows_NT)
#  # Convert Windows paths to POSIX paths
#  ESP_HOME := $(subst \,/,$(addprefix /,$(subst :,,$(ESP_HOME))))
#  ESP_HOME := $(subst //,/,$(ESP_HOME))
#endif

CONFIG_VARS	+= ESP_HOME
ESP_HOME	:= $(call FixPath,$(ESP_HOME))

export ESP_HOME

export PATH			:= $(ESP_HOME)/xtensa-lx106-elf/bin:$(PATH)
XTENSA_TOOLS_ROOT	:= $(ESP_HOME)/xtensa-lx106-elf/bin
CONFIG_TOOLPREFIX	:= xtensa-lx106-elf-
TOOLSPEC			:= $(XTENSA_TOOLS_ROOT)/$(CONFIG_TOOLPREFIX)

# select which tools to use as assembler, compiler, librarian and linker
AS		:= $(TOOLSPEC)gcc
CC		:= $(TOOLSPEC)gcc
CXX		:= $(TOOLSPEC)g++
AR		:= $(TOOLSPEC)ar
LD		:= $(TOOLSPEC)gcc
OBJCOPY := $(TOOLSPEC)objcopy
OBJDUMP := $(TOOLSPEC)objdump
GDB		:= $(TOOLSPEC)gdb

CFLAGS_COMMON	+= -nostdlib -mlongcalls -mtext-section-literals
CFLAGS			+= -D__ets__ -DICACHE_FLASH -DUSE_OPTIMIZE_PRINTF -DESP8266=1

CONFIG_VARS += MFORCE32
MFORCE32 := $(shell $(CC) --help=target | grep mforce-l32)
ifneq ($(MFORCE32),)
    # Your compiler supports the -mforce-l32 flag which means that
    # constants can be stored in flash (program) memory instead of SRAM.
    # See: https://www.arduino.cc/en/Reference/PROGMEM
    CFLAGS += -DPROGMEM_L32="__attribute__((aligned(4))) __attribute__((section(\".irom.text\")))" -mforce-l32
else
    CFLAGS += -DPROGMEM_L32=""
endif

# => 'Internal' SDK - for SDK Version 3+ as submodule in Sming repository
# SDK_BASE just needs to point into our repo as it's overridden with the correct submodule path
# This provides backward-compatiblity, so $(SMING)/third-party/ESP8266_NONOS_SDK) still works
CONFIG_VARS += SDK_BASE SDK_INTERNAL
ifneq (,$(findstring $(abspath $(SMING_HOME)),$(abspath $(SDK_BASE))))
	SDK_COMPONENT	:= $(ARCH_COMPONENTS)/Sdk/ESP8266_NONOS_SDK
	SDK_BASE		:= $(SMING_HOME)/$(SDK_COMPONENT)
	CFLAGS			+= -DSDK_INTERNAL
	SDK_INTERNAL = 1
else
	SDK_INTERNAL = 0
endif

# various paths from the SDK used in this project
SDK_LIBDIR	:= $(SDK_BASE)/lib
SDK_INCDIR	:= $(SDK_BASE)/include

# => Tools
ESPTOOL2	= $(ARCH_TOOLS)/esptool2/esptool2$(TOOL_EXT)
SPIFFY		= $(ARCH_TOOLS)/spiffy/spiffy$(TOOL_EXT)

