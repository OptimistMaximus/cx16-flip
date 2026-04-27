SOURCE := ./src
RESDIR := $(SOURCE)/resources
INCDIR := $(SOURCE)/include

.PHONY: run debug clean test 

CC := cl65 -t cx16
LD := ar65 a

#------------------------------------------------------------------
# Resources
#------------------------------------------------------------------
IMAGE_FILENAME := $(RESDIR)/BELL.FLI
MAIN_RESOURCES := )/IMAGE.FLI

#------------------------------------------------------------------
# Includes
#------------------------------------------------------------------
INCLUDES := $(wildcard $(INCDIR)/*.inc)

#------------------------------------------------------------------
# Libraries
#------------------------------------------------------------------
LIB_CORE_SOURCES  := $(wildcard $(SOURCE)/core/*.asm)
LIB_CORE_OBJECTS  := $(LIB_CORE_SOURCES:$(SOURCE)/core/%.asm=zzz/core/%.o)

LIB_CODEC_SOURCES := $(wildcard $(SOURCE)/codec/*.asm)
LIB_CODEC_OBJECTS := $(LIB_CODEC_SOURCES:$(SOURCE)/codec/%.asm=zzz/codec/%.o)

LIB_TEST_SOURCES := $(wildcard $(SOURCE)/test/*.asm)
LIB_TEST_OBJECTS := $(LIB_TEST_SOURCES:$(SOURCE)/test/%.asm=zzz/test/%.o)

# ca65 seems to need this in reverse-dependency order
MAIN_LIBS := zzz/core.lib zzz/codec.lib
TEST_LIBS := $(MAIN_LIBS) zzz/test.lib

#------------------------------------------------------------------
# Target test (default), debug, clean, run
#------------------------------------------------------------------
test: zzz/TEST.PRG
	cd zzz && x16emu -run -prg -debug 080D TEST.PRG

run: zzz/FLIP.PRG $(MAIN_RESOURCES)
	cd zzz && x16emu -run -prg FLIP.PRG

debug: zzz/FLIP.PRG $(MAIN_RESOURCES)
	cd zzz && x16emu -run -debug 080D -prg FLIP.PRG
	ls -l $<

clean:
	rm -rf zzz

zzz/IMAGE.FLI: $(IMAGE_FILENAME)
	cp $(IMAGE_FILENAME) $@

#------------------------------------------------------------------
# Targets to create directories
#------------------------------------------------------------------
zzz:
	mkdir -p $@

zzz/core:
	mkdir -p $@

zzz/codec:
	mkdir -p $@

zzz/test:
	mkdir -p $@

#------------------------------------------------------------------
# Targets to build programs
#------------------------------------------------------------------
zzz/FLIP.PRG: zzz/main.o $(MAIN_LIBS) $(MAIN_RESOURCES) | zzz
	cd zzz && cl65 -o MAIN.PRG main.o $(MAIN_LIBS)

zzz/TEST.PRG: zzz/test.o $(TEST_LIBS) | zzz
	cd zzz && cl65 -o MAIN.PRG main.o $(TEST_LIBS)

#------------------------------------------------------------------
# Targets to build libraries
#------------------------------------------------------------------
zzz/core.lib: $(LIB_CORE_OBJECTS) | zzz
	cd zzz/core && $(LD) core.lib *.o && mv core.lib ..

zzz/codec.lib: $(LIB_CODEC_OBJECTS) | zzz
	cd zzz/codec && $(LD) codec.lib *.o && mv codec.lib ..

zzz/test.lib: $(LIB_TEST_OBJECTS) | zzz
	cd zzz/test && $(LD) test.lib *.o && mv ..

#------------------------------------------------------------------
# Targets to build sources
#------------------------------------------------------------------
zzz/core/%.o: $(SOURCE)/core/%.asm $(INCLUDES) | zzz/core
	cd $(dir $<) && $(CC) -c $(notdir $<) -o $(notdir $@) && mv $(notdir $@) ../../$(dir $@)

zzz/codec/%.o: $(SOURCE)/codec/%.asm $(INCLUDES) | zzz/codec
	cd $(dir $<) && $(CC) -c $(notdir $<) -o $(notdir $@) && mv $(notdir $@) ../../$(dir $@)

zzz/test/%.o: $(SOURCE)/test/%.asm $(INCLUDES) | zzz/test
	cd $(dir $<) && $(CC) -c $(notdir $<) -o $(notdir $@) && mv $(notdir $@) ../../$(dir $@)

zzz/%.o: $(SOURCE)/%.asm $(INCLUDES) | zzz
	cd $(SOURCE) && $(CC) -c $(notdir $<) -o $(notdir $@) && mv $(notdir $@) ../zzz

