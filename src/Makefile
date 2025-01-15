# Compilador e flags
CXX = g++
CXXFLAGS = -Wall -O2

# Diretórios e arquivos
SRC_DIR = src
BIN_DIR = ../bin
TARGET = $(BIN_DIR)/contagem

# Arquivos fonte
SRCS = contagem.cpp
OBJS = $(SRCS:.cpp=.o)

# Regra principal
all: $(BIN_DIR) $(TARGET)

# Criar diretório bin se não existir
$(BIN_DIR):
	mkdir -p $(BIN_DIR)

# Compilar o programa
$(TARGET): $(OBJS)
	$(CXX) $(OBJS) -o $(TARGET)

# Regra para arquivos objeto
%.o: %.cpp
	$(CXX) $(CXXFLAGS) -c $< -o $@

# Limpar arquivos compilados
clean:
	rm -f $(OBJS) $(TARGET)
	rm -rf $(BIN_DIR)

.PHONY: all clean
