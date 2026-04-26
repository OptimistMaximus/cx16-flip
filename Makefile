ROOT   := $(shell pwd)
SOURCE := $(ROOT)/src
TARGET := $(ROOT)/target
RESDIR := $(SOURCE)/resources
INCDIR := $(SOURCE)/include

.PHONY: run debug clean

#------------------------------------------------------------------
# Resources
#------------------------------------------------------------------
IMAGE_FILENAME := $(RESDIR)/BELL.FLI

#------------------------------------------------------------------
# Includes
#------------------------------------------------------------------
INCLUDES := $(wildcard $(INCDIR)/*.inc)

#------------------------------------------------------------------
# Libraries
#------------------------------------------------------------------
LIB_CORE_SOURCES  := $(wildcard $(SOURCE)/core/*.asm)
LIB_CODEC_SOURCES := $(wildcard $(SOURCE)/codec/*.asm)
LIB_CORE_OBJECTS  := $(LIB_CORE_SOURCES:$(SOURCE)/core/%.asm=$(TARGET)/core/%.o)
LIB_CODEC_OBJECTS := $(LIB_CODEC_SOURCES:$(SOURCE)/codec/%.asm=$(TARGET)/codec/%.o)

# ca65 seems to need this in reverse-dependency order
LIBS_AS_ARGS := core.lib codec.lib
LIBS_AS_DEPS := $(TARGET)/core.lib $(TARGET)/codec.lib

#------------------------------------------------------------------
# Target run (default), debug, clean
#------------------------------------------------------------------
run: $(TARGET)/FLIP.PRG $(TARGET)/IMAGE.FLI
	cd $(TARGET) && x16emu -run -prg FLIP.PRG

debug: $(TARGET)/FLIP.PRG $(TARGET)/IMAGE.FLI
	cd $(TARGET) && x16emu -run -debug 080D -prg FLIP.PRG
	ls -l $<

clean:
	rm -f $(TARGET)/*.o
	rm -f $(TARGET)/*.PRG
	rm -f $(TARGET)/*.FLI
	rm -f $(TARGET)/*.FLC

#------------------------------------------------------------------
# Targets to create directories and copy resources
#------------------------------------------------------------------
$(TARGET):
	mkdir $@

$(TARGET)/core: | $(TARGET)
	mkdir $@

$(TARGET)/codec: | $(TARGET)
	mkdir $@

$(TARGET)/IMAGE.FLI: | $(IMAGE_FILENAME)
	cp $(IMAGE_FILENAME) $@

#------------------------------------------------------------------
# Targets to build programs
#------------------------------------------------------------------
$(TARGET)/FLIP.PRG: $(TARGET)/main.o $(LIBS_AS_DEPS) $(TARGET)/IMAGE.FLI
	cd $(TARGET) && cl65 -o FLIP.PRG main.o $(LIBS_AS_ARGS)

#------------------------------------------------------------------
# Targets to build libraries
#------------------------------------------------------------------
$(TARGET)/core.lib: $(LIB_CORE_OBJECTS)
	cd $(TARGET)/core && ar65 a core.lib *.o && mv core.lib $(TARGET)

$(TARGET)/codec.lib: $(LIB_CODEC_OBJECTS)
	cd $(TARGET)/codec && ar65 a codec.lib *.o && mv codec.lib $(TARGET)

#------------------------------------------------------------------
# Targets to build sources
#
# I can't figure out how to make cc65 honor relative paths, hence
# the crude changing of directory and subsequent move	
#------------------------------------------------------------------
$(TARGET)/core/%.o: $(SOURCE)/core/%.asm $(INCLUDES) | $(TARGET)/core
	cd $(dir $<) && cl65 -t cx16 -c $(notdir $<) -o $(notdir $@) && mv $(notdir $@) $@

$(TARGET)/codec/%.o: $(SOURCE)/codec/%.asm $(INCLUDES) | $(TARGET)/codec
	cd $(dir $<) && cl65 -t cx16 -c $(notdir $<) -o $(notdir $@) && mv $(notdir $@) $@

$(TARGET)/%.o: $(SOURCE)/%.asm $(INCLUDES) | $(TARGET)
	cd $(dir $<) && cl65 -t cx16 -c $(notdir $<) -o $(notdir $@) && mv $(notdir $@) $@



