CROSSAS	= /opt/m68k/bin/m68k-coff-as
CROSSLD	= /opt/m68k/bin/m68k-coff-ld

OBJS	= init.o firststeps.o
BIN	= firststeps.bin

.PHONY: all
all:	$(BIN)

.PHONY: tar
tar:
	zip firststeps.zip $(BIN) *.S *.inc Makefile

.PHONY: clean
clean:
	rm -f $(OBJS) $(BIN)


$(BIN): $(OBJS)
	$(CROSSLD) $(OBJS) --oformat binary -o $(BIN)


.SUFFIXES:
.SUFFIXES: .o

%.o: %.S
	$(CROSSAS) $< -o $@
