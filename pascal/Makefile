# Makefile para compilar o projeto de Autômatos Finitos em Pascal

# Compilador
FPC = fpc

# Flags de compilação
FPCFLAGS = -O2 -v0

# Arquivo principal
MAIN = main.pas

# Executável
TARGET = automatos

# Units
UNITS = tipos.pas utilidades.pas leitorjson.pas simulador.pas conversores.pas

all: $(TARGET)

$(TARGET): $(MAIN) $(UNITS)
	$(FPC) $(FPCFLAGS) -o$(TARGET) $(MAIN)

clean:
	rm -f *.o *.ppu $(TARGET)

run: $(TARGET)
	./$(TARGET)

.PHONY: all clean run
