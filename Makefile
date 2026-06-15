SOURCE := ./src
RESDIR := $(SOURCE)/resources
INCDIR := $(SOURCE)/include

VERSION := 080
PROGRAM := FLIP$(VERSION).PRG
LIBRARY := FLIP$(VERSION).DLL

.PHONY: run debug clean test dll

#------------------------------------------------------------------
# Resources
#------------------------------------------------------------------
IMAGE_FILENAME := $(RESDIR)/STARTREK.FLI
MAIN_RESOURCES := zzz/IMAGE.FLI

TEST_DATA_FILES := \
$(RESDIR)/HEADER0.hex \
$(RESDIR)/HEADER1.hex \
$(RESDIR)/HEADER2.hex \
$(RESDIR)/CHUNK0.hex \
$(RESDIR)/CHUNK1.hex \
$(RESDIR)/CHUNK3.hex \
$(RESDIR)/CHUNK4.hex \
$(RESDIR)/CHUNK5.hex \
$(RESDIR)/CHUNK6.hex \
$(RESDIR)/COLOR0.hex \
$(RESDIR)/COLOR1.hex \
$(RESDIR)/COLOR2.hex \
$(RESDIR)/BYTERUN.hex \
$(RESDIR)/DELTAFLI.hex \
$(RESDIR)/CACHE11.hex \
$(RESDIR)/CACHE260.hex

TEST_RESOURCES := $(TEST_DATA_FILES:$(RESDIR)/%.hex=zzz/%.BIN)

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
DLL_CODEC_OBJECTS := $(LIB_CODEC_SOURCES:$(SOURCE)/codec/%.asm=zzz/codec/%.so)

LIB_TEST_SOURCES := $(wildcard $(SOURCE)/test/*.asm)
LIB_TEST_OBJECTS := $(LIB_TEST_SOURCES:$(SOURCE)/test/%.asm=zzz/test/%.o)

# ca65 seems to need this in reverse-dependency order
MAIN_LIBS := zzz/core.lib zzz/codec.lib
TEST_LIBS := zzz/test.lib $(MAIN_LIBS)

#------------------------------------------------------------------
# Target test (default), debug, clean, run
#------------------------------------------------------------------
hack: zzz/HACK.PRG
	cd zzz && x16emu -run -prg HACK.PRG

test: zzz/TEST.PRG $(TEST_RESOURCES)
	cd zzz && x16emu -run -debug 080D -prg TEST.PRG

run: zzz/$(PROGRAM) zzz/$(LIBRARY) $(MAIN_RESOURCES)
	cd zzz && x16emu -run -prg $(PROGRAM)
	ls -l $<

dll: zzz/$(LIBRARY)

debug: zzz/$(PROGRAM) $(MAIN_RESOURCES)
	cd zzz && x16emu -run -debug 080D -prg $(PROGRAM) -dump V
	ls -l $<

clean:
	rm -rf zzz

zzz/TEST.TXT: $(TEST_FILENAME)
	cp $(TEST_FILENAME) $@

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
zzz/$(PROGRAM): zzz/main.o $(MAIN_LIBS) $(MAIN_RESOURCES) | zzz
	cl65 -o $@ $< $(MAIN_LIBS)

zzz/TEST.PRG: zzz/test.o $(TEST_LIBS) | zzz
	cl65 -o $@ $< $(TEST_LIBS)

zzz/HACK.PRG: zzz/hack.o $(MAIN_LIBS) | zzz
	cl65 -o $@ $< $(MAIN_LIBS)

#------------------------------------------------------------------
# Targets to build libraries
#------------------------------------------------------------------
zzz/$(LIBRARY): $(DLL_CODEC_OBJECTS)
	ld65 -C dll.cfg $^ -o $@
	ls -l $@

zzz/core.lib: $(LIB_CORE_OBJECTS) | zzz
	ar65 a $@ zzz/core/*.o

zzz/codec.lib: $(LIB_CODEC_OBJECTS) | zzz
	ar65 a $@ zzz/codec/*.o

zzz/test.lib: $(LIB_TEST_OBJECTS) | zzz
	ar65 a $@ zzz/test/*.o

#------------------------------------------------------------------
# Targets to build sources
#
# Note, cl65 is very picky about order of arguments.
#
#       cl65 -t cx16 -c src/bar.asm -o zzz/bar.o
#
# will ignore the output path and just put the object in the same
# directory as the source.  But if you use the following order
# then it works as you would intuitively expect:
#
#       cl65 -t cx16 -o zzz/bar.o -c src/bar.asm
#
#------------------------------------------------------------------
zzz/core/%.so: $(SOURCE)/core/%.asm $(INCLUDES) | zzz/core
	cl65 -t none --cpu 65c02 -C dll.cfg -o $@ -c $<

zzz/codec/%.so: $(SOURCE)/codec/%.asm $(INCLUDES) | zzz/codec
	cl65 -t none --cpu 65c02 -C dll.cfg -D FLIPDLL=1 -o $@ -c $<

zzz/core/%.o: $(SOURCE)/core/%.asm $(INCLUDES) | zzz/core
	cl65 -t cx16 -o $@ -c $<

zzz/codec/%.o: $(SOURCE)/codec/%.asm $(INCLUDES) | zzz/codec
	cl65 -t cx16 -o $@ -c $<

zzz/test/%.o: $(SOURCE)/test/%.asm $(INCLUDES) | zzz/test
	cl65 -t cx16 -o $@ -c $<

zzz/main.o: $(SOURCE)/main.asm $(INCLUDES) | zzz
	cl65 -t cx16 -o $@ -c $<

zzz/test.o: $(SOURCE)/test.asm $(INCLUDES) | zzz
	cl65 -t cx16 -o $@ -c $<

zzz/hack.o: $(SOURCE)/hack.asm $(INCLUDES) | zzz
	cl65 -t cx16 -o $@ -c $<

#------------------------------------------------------------------
# Targets to build test inputs
#------------------------------------------------------------------
zzz/%.BIN: $(RESDIR)/%.hex | $(TARGET)
	sh hex2bin.sh $< $@
