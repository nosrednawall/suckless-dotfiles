.POSIX:

BIN := dwmblocks
BUILD_DIR := build
SRC_DIR := src
INC_DIR := include
CONFIG_FILE := config.def.h
CONFIG_HEADER := config.h

DEBUG := 1
VERBOSE := 1
LIBS := xcb-atom xcb

PREFIX := /usr/local
CFLAGS := -Ofast -I. -I$(INC_DIR) -std=c99
CFLAGS += -DBINARY=\"$(BIN)\" -D_POSIX_C_SOURCE=200809L
CFLAGS += -Wall -Wpedantic -Wextra -Wswitch-enum
CFLAGS += $(shell pkg-config --cflags $(LIBS))
LDLIBS := $(shell pkg-config --libs $(LIBS))

SRCS := $(wildcard $(SRC_DIR)/*.c)
OBJS := $(subst $(SRC_DIR)/,$(BUILD_DIR)/,$(SRCS:.c=.o))

#INSTALL_DIR := $(DESTDIR)$(PREFIX)/bin
INSTALL_DIR := $(PREFIX)/bin

# Prettify output
PRINTF := @printf "%-8s %s\n"
ifeq ($(VERBOSE), 0)
	Q := @
endif

ifeq ($(DEBUG), 1)
	CFLAGS += -g
endif

all: $(BUILD_DIR)/$(BIN)

# Rule to copy config.def.h to config.h
$(CONFIG_HEADER): $(CONFIG_FILE)
	$(PRINTF) "COPY" $@
	$Qcp $< $@

# Rule to build object files
$(BUILD_DIR)/%.o: $(SRC_DIR)/%.c $(CONFIG_HEADER)
	$Qmkdir -p $(@D)
	$(PRINTF) "CC" $@
	$Q$(COMPILE.c) -o $@ $<

# Rule to build the binary
$(BUILD_DIR)/$(BIN): $(OBJS)
	$(PRINTF) "LD" $@
	$Q$(LINK.o) $^ $(LDLIBS) -o $@

# Clean up build files
clean:
	$(PRINTF) "CLEAN" $(BUILD_DIR)
	$Q$(RM) -r $(BUILD_DIR)

# Install the binary
install: $(BUILD_DIR)/$(BIN)
	$(PRINTF) "INSTALL" $(INSTALL_DIR)/$(BIN)
	$Qinstall -D -m 755 $< $(INSTALL_DIR)/dwmblocks

# Uninstall the binary
uninstall:
	$(PRINTF) "RM" $(INSTALL_DIR)/$(BIN)
	$Q$(RM) $(INSTALL_DIR)/$(BIN)

.PHONY: all clean install uninstall
