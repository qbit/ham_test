# $OpenBSD: Makefile,v 1.3 2014/10/30 21:44:30 edd Exp $
# Arduino Makefile
# Arduino adaptation by mellis, eighthave, oli.keller
# Adapted for BSD make(1) by Seth Wright (seth@crosse.org)
# Adapted for OpenBSD ports by Chris Kuethe (ckuethe@openbsd.org)
# Later maintained by the OpenBSD ports team (ports@openbsd.org)
# Later overhauled by Edd Barrett (edd@openbsd.org)
#
# This makefile allows you to build sketches from the command line
# without the Arduino environment (or Java).
#
# If you have problems, please add a test case and raise an issue here:
# https://github.com/vext01/openbsd_arduino_tests
#
# Usage:
#  1) Define your target and libraries below.
#  2) make
#  3) make upload (with appropriate permissions for PORT)
#
# Target options.
#
# You will need to specify the following options to compile and upload
# code to your Arduino board:
#
# UPLOAD_RATE: baud rate for programming.
# PORT: device to program over.
# AVRDUDE_PROGRAMMER: Kind of programming interface.
# MCU: AVR CPU on the board. See avrdude config file for possible values.
# F_CPU: CPU frequency. Usually 16000000.
# VARIANT: Arduino peripheral configuration, one of:
#          {eightanaloginputs, leonardo, mega, micro, standard}
# ARDUINO_ARCH: Arduino architecture. 'avr' or 'sam' (aka ARM).
#               Note that sam is not yet supported.
#
# Below are some known working hardware configurations. If you find other
# working configurations, please feed them back to the OpenBSD port maintainer.

# Change this to the location of your HamShield libraries.
# Also add the included alibs.mk file to is directory.
USER_LIBRARIES=/home/qbit/dev/arduino_libs/

PORT ?= /dev/cuaU0

## Arduino Uno
ARDUINO_ARCH?=avr
UPLOAD_RATE ?= 115200
AVRDUDE_PROGRAMMER ?= arduino
MCU ?= atmega328p
F_CPU ?= 16000000
VARIANT ?= standard

# Arduino Duemilanove
#ARDUINO_ARCH?=avr
#UPLOAD_RATE ?= 57600
#AVRDUDE_PROGRAMMER ?= arduino
#MCU ?= atmega328p
#F_CPU ?= 16000000
#VARIANT ?= standard

## Arduino Mega
#ARDUINO_ARCH?=avr
#UPLOAD_RATE ?= 57600
#AVRDUDE_PROGRAMMER ?= arduino
#MCU ?= atmega1280
#F_CPU ?= 16000000
#VARIANT ?= mega

## older Arduino
#ARDUINO_ARCH?=avr
#UPLOAD_RATE ?= 19200
#AVRDUDE_PROGRAMMER ?= stk500
#MCU ?= atmega328p
#F_CPU ?= 16000000
#VARIANT ?= standard

# If your sketch uses any libraries, list them here.
#
# E.g.:
#LIBRARIES?=LiquidCrystal
#
# Or for ethernet support (which depends upon SPI support)
#LIBRARIES?=Ethernet SPI
#
# For a full list see /usr/local/share/arduino/mk/alibs.mk

LIBRARIES?=DDS HamShield_comms KISS AFSK HamShield

# You can add extra flags and sources here if you know what you are doing
#
#USER_CFLAGS=
#USER_CXXFLAGS=
#USER_LDFLAGS=
#USER_ASFLAGS=

#USER_CXX_SRC=myfile.cpp
#USER_C_SRC=myfile.c
#USER_INC_DIRS=/extra/include/dir

# Some boards, like the Esplora, require you to define some USB details:
#USER_CXXFLAGS +=	-DUSB_VID=0x2341  \
#			-DUSB_PID=0x803c \
#			-DUSB_MANUFACTURER=Unknown \
#			-DUSB_PRODUCT='Arduino Esplora'

############################################################################
# Below here nothing should be changed...

TARGET = ${.CURDIR:C/.*\///g}

ARDUINO_SUPPORT = arduino-support
AVR_TOOLS_PATH = /usr/local/bin

.include "/usr/local/share/arduino/mk/acores.mk"
SRC =   ${${ARDUINO_ARCH}_CORE_C_SRC}
CXXSRC =${${ARDUINO_ARCH}_CORE_CXX_SRC}
COREINC=${${ARDUINO_ARCH}_CORE_INC_DIRS:S/^/-I/}

.include "/usr/local/share/arduino/mk/alibs.mk"
.for l in ${LIBRARIES}
CXXSRC +=	${${l}_${ARDUINO_ARCH}_CXX_SRC}
SRC +=		${${l}_${ARDUINO_ARCH}_C_SRC}
LIBINC +=	${${l}_${ARDUINO_ARCH}_INC_DIRS:S/^/-I/}
.endfor

.include "${USER_LIBRARIES}/alibs.mk"
.for l in ${LIBRARIES}
CXXSRC +=	${${l}_${ARDUINO_ARCH}_CXX_SRC}
SRC +=		${${l}_${ARDUINO_ARCH}_C_SRC}
LIBINC +=	${${l}_${ARDUINO_ARCH}_INC_DIRS:S/^/-I/}
.endfor

CXXSRC += ${USER_CXX_SRC}
SRC += ${USER_C_SRC}
LIBINC += ${USER_INC_DIRS:S/^/-I/}

FORMAT = ihex

# Name of this Makefile (used for "make depend").
MAKEFILE = Makefile

# Debugging format.
# Native formats for AVR-GCC's -g are stabs [default], or dwarf-2.
# AVR (extended) COFF requires stabs, plus an avr-objcopy run.
DEBUG = stabs

# C options
COPT = s
CDEFS = -DF_CPU=$(F_CPU) -DARDUINO=100 -DARDUINO_ARCH_AVR
CINCS = $(LIBINC) ${COREINC} \
	-I$(ARDUINO_SUPPORT)/${ARDUINO_ARCH}/variants/$(VARIANT)
CSTANDARD = -std=gnu99
CDEBUG = -g$(DEBUG)
CWARN = -Wall -Wstrict-prototypes
CTUNING = -ffunction-sections -fdata-sections

# Avoids undefined symbols for e.g. Ethernet library
# https://github.com/Pinoccio/core-pinoccio/commit/e0a452af2704ce671610d38b90aa3bb8a229c9cf
CTUNING += -fno-threadsafe-statics

#CTUNING = -funsigned-char -funsigned-bitfields -fpack-struct -fshort-enums
#CEXTRA = -Wa,-adhlns=$(<:.c=.lst)
CFLAGS = $(CDEBUG) $(CDEFS) $(CINCS) -O$(OPT) $(CWARN) \
	 $(CSTANDARD) $(CEXTRA) $(CTUNING)

# C++ options
CXXOPT = ${COPT}
CXXDEFS = -DF_CPU=$(F_CPU) -DARDUINO=100 -DARDUINO_ARCH_AVR
CXXINCS = ${CINCS}
CXXSTANDARD =
CXXDEBUG = ${CDEBUG}
CXXWARN =
CXXTUNING = ${CTUNING}
CXXEXTRA = ${CEXTRA}
CXXFLAGS = $(CXXDEBUG) $(CXXDEFS) $(CXXINCS) -O$(CXXOPT) $(CXXWARN) \
	 $(CXXSTANDARD) $(CXXEXTRA) $(CXXTUNING)

# Linker stuff
# Web search shows it is important for -lm to come last.
LDFLAGS = -Wl,--gc-sections ${USER_LDFLAGS} -lm

# Assembler stuff
#ASFLAGS = -Wa,-adhlns=$(<:.S=.lst),-gstabs

# Programming support using avrdude. Settings and variables.
AVRDUDE_PORT = $(PORT)
AVRDUDE_WRITE_FLASH = -U flash:w:applet/$(TARGET).hex
AVRDUDE_CONF = /etc/avrdude.conf
AVRDUDE_FLAGS = -V -F -C $(AVRDUDE_CONF) -p $(MCU) -P $(AVRDUDE_PORT) \
-c $(AVRDUDE_PROGRAMMER) -b $(UPLOAD_RATE)

# Program settings
CC = $(AVR_TOOLS_PATH)/avr-gcc
CXX = $(AVR_TOOLS_PATH)/avr-g++
OBJCOPY = $(AVR_TOOLS_PATH)/avr-objcopy
OBJDUMP = $(AVR_TOOLS_PATH)/avr-objdump
AR  = $(AVR_TOOLS_PATH)/avr-ar
SIZE = $(AVR_TOOLS_PATH)/avr-size
NM = $(AVR_TOOLS_PATH)/avr-nm
AVRDUDE = $(AVR_TOOLS_PATH)/avrdude
REMOVE = rm -f
FORCE_REMOVE_DIR = rm -rf
REMOVEDIR = rmdir
MKDIR = mkdir -p
MV = mv -f
LNDIR = lndir

# Define all object files.
OBJ = $(SRC:.c=.o) $(CXXSRC:.cpp=.o) $(ASRC:.S=.o)

# Define all listing files.
LST = $(ASRC:.S=.lst) $(CXXSRC:.cpp=.lst) $(SRC:.c=.lst)

# Combine all necessary flags and optional flags.
# Add target processor to flags.
ALL_CFLAGS = -mmcu=$(MCU) -I. $(CFLAGS) ${USER_CFLAGS}
ALL_CXXFLAGS = -mmcu=$(MCU) -I. $(CXXFLAGS) ${USER_CXXFLAGS}
ALL_ASFLAGS = -mmcu=$(MCU) -I. -x assembler-with-cpp $(ASFLAGS) ${USER_ASFLAGS}


# Default target.
all: applet_files build sizeafter

build: mkdirs elf hex

mkdirs:
	if [ ! -d ${ARDUINO_SUPPORT} ]; then \
		mkdir -p ${ARDUINO_SUPPORT}; \
		${LNDIR} /usr/local/share/arduino ${ARDUINO_SUPPORT}; \
		${LNDIR} ${USER_LIBRARIES} ${ARDUINO_SUPPORT}/libraries; \
	fi

# Here is the "preprocessing".
# It creates a .cpp file based with the same name as the .ino file.
# On top of the new .cpp file comes the Arduino.h header.
# Then comes a stdc++ workaround, see:                                          
# http://stackoverflow.com/questions/920500/what-is-the-purpose-of-cxa-pure-virtual
# At the end there is a generic main() function attached.
# Then the .cpp file will be compiled. Errors during compile will
# refer to this new, automatically generated, file.
# Not the original .ino file you actually edit...
applet_files: $(TARGET).ino mkdirs
	test -d applet || mkdir applet
	echo '#include "Arduino.h"' > applet/$(TARGET).cpp
	echo '#ifdef __cplusplus' >> applet/$(TARGET).cpp
	echo 'extern "C" void __cxa_pure_virtual(void) { while(1); }' \
		>> applet/$(TARGET).cpp
	echo '#endif\n' >> applet/$(TARGET).cpp
	cat $(TARGET).ino >> applet/$(TARGET).cpp
	cat $(ARDUINO_SUPPORT)/${ARDUINO_ARCH}/cores/arduino/main.cpp >> applet/$(TARGET).cpp

elf: applet/$(TARGET).elf
hex: applet/$(TARGET).hex
eep: applet/$(TARGET).eep
lss: applet/$(TARGET).lss
sym: applet/$(TARGET).sym

# Program the device.
upload: applet/$(TARGET).hex
	$(AVRDUDE) $(AVRDUDE_FLAGS) $(AVRDUDE_WRITE_FLASH)

console: upload
	cu -s 9600 -l $(PORT)

# Display size of file.
HEXSIZE = $(SIZE) --target=$(FORMAT) applet/$(TARGET).hex
ELFSIZE = $(SIZE)  applet/$(TARGET).elf
sizebefore:
	@if [ -f applet/$(TARGET).elf ]; then echo; echo $(MSG_SIZE_BEFORE); $(HEXSIZE); echo; fi

sizeafter: applet/$(TARGET).hex
	@if [ -f applet/$(TARGET).elf ]; then echo; echo $(MSG_SIZE_AFTER); $(HEXSIZE); echo; fi


# Convert ELF to COFF for use in debugging / simulating in AVR Studio or VMLAB.
COFFCONVERT=$(OBJCOPY) --debugging \
--change-section-address .data-0x800000 \
--change-section-address .bss-0x800000 \
--change-section-address .noinit-0x800000 \
--change-section-address .eeprom-0x810000


coff: applet/$(TARGET).elf
	$(COFFCONVERT) -O coff-avr applet/$(TARGET).elf $(TARGET).cof


extcoff: $(TARGET).elf
	$(COFFCONVERT) -O coff-ext-avr applet/$(TARGET).elf $(TARGET).cof


.SUFFIXES: .elf .hex .eep .lss .sym .cpp .o .c .s .S

.elf.hex:
	$(OBJCOPY) -O $(FORMAT) -R .eeprom $< $@

.elf.eep:
	-$(OBJCOPY) -j .eeprom --set-section-flags=.eeprom="alloc,load" \
	--change-section-lma .eeprom=0 -O $(FORMAT) $< $@

# Create extended listing file from ELF output file.
.elf.lss:
	$(OBJDUMP) -h -S $< > $@

# Create a symbol table from ELF output file.
.elf.sym:
	$(NM) -n $< > $@

# Link: create ELF output file from library.
# Link with ${CC}. In some cases linking with ${CXX} gives undefined symbols.
applet/$(TARGET).elf: $(TARGET).ino applet/core.a
	$(CC) $(ALL_CXXFLAGS) -o $@ applet/$(TARGET).cpp -L. applet/core.a $(LDFLAGS)

applet/core.a: $(OBJ)
	@for i in $(OBJ); do echo $(AR) rcs applet/core.a $$i; $(AR) rcs applet/core.a $$i; done


# Compile: create object files from C++ source files.
.cpp.o:
	$(CXX) -c $(ALL_CXXFLAGS) $< -o $@

# Compile: create object files from C source files.
.c.o:
	$(CC) -c $(ALL_CFLAGS) $< -o $@


# Compile: create assembler files from C source files.
.c.s:
	$(CC) -S $(ALL_CFLAGS) $< -o $@


# Assemble: create object files from assembler source files.
.S.o:
	$(CC) -c $(ALL_ASFLAGS) $< -o $@


# Automatic dependencies
%.d: %.c
	$(CC) -M $(ALL_CFLAGS) $< | sed "s;$(notdir $*).o:;$*.o $*.d:;" > $@

%.d: %.cpp
	$(CXX) -M $(ALL_CXXFLAGS) $< | sed "s;$(notdir $*).o:;$*.o $*.d:;" > $@


# Target: clean project.
clean:
	${FORCE_REMOVE_DIR} applet ${ARDUINO_SUPPORT}

.PHONY:	all build elf hex eep lss sym program coff extcoff clean applet_files sizebefore sizeafter

