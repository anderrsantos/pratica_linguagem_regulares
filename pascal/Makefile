# Makefile para compilar o projeto de Autômatos Finitos em Pascal

# Compilador
FPC = fpc

# Diretórios
SRC_DIR = src

# Flags de compilação (inclui diretório das units)
FPCFLAGS = -O2 -v0 -Fu$(SRC_DIR)

# Arquivos fonte
MAIN = $(SRC_DIR)/main.pas
UNITS = $(SRC_DIR)/tipos.pas \
	$(SRC_DIR)/utilidades.pas \
	$(SRC_DIR)/leitorjson.pas \
	$(SRC_DIR)/simulador.pas \
	$(SRC_DIR)/conversores.pas

# Executável ficará dentro de src/
TARGET = $(SRC_DIR)/automatos

all: $(TARGET)

$(TARGET): $(MAIN) $(UNITS)
	$(FPC) $(FPCFLAGS) -o$(TARGET) $(MAIN)

clean:
	rm -f $(SRC_DIR)/*.o $(SRC_DIR)/*.ppu $(TARGET)

run: $(TARGET)
	./$(TARGET)

.PHONY: all clean run
