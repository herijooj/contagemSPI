#!/bin/bash

# Implementado por Eduardo Machado (2016)
# Modified by Lucas Nogueira (2023)
# Modified by Heric Camargo (2025)

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

set_colors() {
    RED='\033[1;31m'
    GREEN='\033[1;32m'
    YELLOW='\033[1;93m'
    BLUE='\033[1;36m'
    PURPLE='\033[1;35m'
    CYAN='\033[0;36m'
    GRAY='\033[0;90m'
    BOLD='\033[1m'
    NC='\033[0m'
}

if [ -t 1 ] && ! grep -q -e '--no-color' <<<"$@"
then
    set_colors
fi

# Define arrays for seasons and percentages
SEASONS=("DJF" "MAM" "JJA" "SON")
PERCENTAGES=(70 80)
CUT_LINES=(-2.0 -1.5 1.0 2.0)

# Check if input directory or file is provided
if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
    echo -e "${RED}ERRO! Parametros errados! Utilize:${NC}"
    echo -e "${YELLOW}script.sh [DIRETORIO_OU_ARQUIVO_ENTRADA] [TXT_OU_BIN]${NC}"
    echo
    echo -e "${BLUE} - TXT_OU_BIN = 0, cria arquivo texto com os resultados.${NC}"
    echo -e "${BLUE} - TXT_OU_BIN = 1, cria arquivo binário e controle com resultados (padrão).${NC}"
    echo -e "${BLUE} - TXT_OU_BIN = 2, cria os dois tipos de arquivos.${NC}"
    exit 1
fi

INPUT_PATH="$1"
TXT_OR_BIN="${2:-1}"  # Default to 1 if not specified

# Create output directory structure
BASE_OUTPUT_DIR="output"
mkdir -p "$BASE_OUTPUT_DIR"

# Process input path
if [ -f "$INPUT_PATH" ] && [[ "$INPUT_PATH" == *.ctl ]]; then
    # Single file processing
    CTL_FILES=("$INPUT_PATH")
else
    # Directory processing
    CTL_FILES=("$INPUT_PATH"/*.ctl)
fi

# Process each .ctl file
for CTL_FILE in "${CTL_FILES[@]}"; do
    if [ ! -f "$CTL_FILE" ]; then
        echo -e "${RED}[ERRO]${NC} Nenhum arquivo .ctl encontrado em $INPUT_PATH"
        exit 1
    fi

    echo -e "\n${BOLD}${PURPLE}=== Processando arquivo: ${CYAN}$(basename "$CTL_FILE")${NC} ===\n"

    # Create output subdirectories for the current file
    CTL_BASE=$(basename "$CTL_FILE" .ctl)
    FILE_OUTPUT_DIR="$BASE_OUTPUT_DIR/$CTL_BASE"
    mkdir -p "$FILE_OUTPUT_DIR"

    # Process each combination of parameters
    for SEASON in "${SEASONS[@]}"; do
        for PERCENTAGE in "${PERCENTAGES[@]}"; do
            for CUT_LINE in "${CUT_LINES[@]}"; do
                echo -e "${BLUE}[CONFIG]${NC} Estação: ${YELLOW}$SEASON${NC}, Percentual: ${YELLOW}$PERCENTAGE%${NC}, Linha de Corte: ${YELLOW}$CUT_LINE${NC}"

                # Create season directory
                SEASON_DIR="$FILE_OUTPUT_DIR/$SEASON"
                mkdir -p "$SEASON_DIR"

                # Create percentage directory
                PERC_DIR="$SEASON_DIR/perc_$PERCENTAGE"
                mkdir -p "$PERC_DIR"

                # Create cut line directory
                CUT_DIR="$PERC_DIR/cut_${CUT_LINE/./_}"
                echo -e "${GRAY}[INFO]${NC} Criando diretórios..."
                mkdir -p "$CUT_DIR" && echo -e "${GREEN}[OK]${NC} Diretórios criados com sucesso"

                # Run the original script logic with new parameters
                ARQ_CTL_IN="$CTL_FILE"
                
                # Execute the existing logic (previous script content here)
                ARQ_BIN_IN="$(grep -i -w '^dset' $ARQ_CTL_IN | xargs | cut -d" " -f2)"
                
                if [ "${ARQ_BIN_IN:0:1}" = "^" ]; then 
                    ARQ_BIN_IN="$(dirname $ARQ_CTL_IN)/$(basename ${ARQ_BIN_IN:1})"
                fi

                VAR=$(grep -A1 -i -w '^vars' ${ARQ_CTL_IN} | tail -n1 | awk '{print $1}')
                NX=$(grep -i -w '^xdef' ${ARQ_CTL_IN} | xargs | cut -d" " -f2)
                NY=$(grep -i -w '^ydef' ${ARQ_CTL_IN} | xargs | cut -d" " -f2)
                NZ=$(grep -i -w '^zdef' ${ARQ_CTL_IN} | xargs | cut -d" " -f2)
                NT=$(grep -i -w '^tdef' ${ARQ_CTL_IN} | xargs | cut -d" " -f2)
                UNDEF=$(grep -i -w '^undef' ${ARQ_CTL_IN}| xargs | cut -d" " -f2)

                # Set output files in the appropriate directory
                ARQ_BIN_OUT="$CUT_DIR/$(basename $ARQ_BIN_IN .bin)_${CUT_LINE}"
                ARQ_CTL_OUT="$CUT_DIR/$(basename $ARQ_CTL_IN .ctl)_${CUT_LINE}_${SEASON}.ctl"

                # Execute contagem program
                #echo -e "${BOLD}${BLUE}[EXECUÇÃO]${NC} Iniciando programa contagem..."
                if $SCRIPT_DIR/bin/contagem ${ARQ_BIN_IN} ${NX} ${NY} ${NZ} ${NT} ${UNDEF} ${CUT_LINE} ${TXT_OR_BIN} ${SEASON} ${ARQ_BIN_OUT} ${PERCENTAGE}; then
                    echo -e "${GREEN}[SUCESSO]${NC} Programa contagem executado com sucesso"
                else
                    echo -e "${RED}[FALHA]${NC} Erro na execução do programa contagem"
                    exit 1
                fi

                # Handle output files based on TXT_OR_BIN
                echo -e "${GRAY}[INFO]${NC} Processando arquivos de saída..."
                if [[ ${TXT_OR_BIN} -eq "1" ]] || [[ ${TXT_OR_BIN} -eq "2" ]]; then
                    cp $ARQ_CTL_IN $ARQ_CTL_OUT
                    sed -i "s#$(basename $ARQ_BIN_IN .bin)#$(basename ${ARQ_BIN_OUT}_${SEASON} .bin)#g" ${ARQ_CTL_OUT}
                    sed -i -E "s/^tdef[[:space:]]+[0-9]+/tdef 1/I" ${ARQ_CTL_OUT}
                    #echo -e "${GREEN}[OK]${NC} Arquivos binários processados"
                fi

                if [[ ${TXT_OR_BIN} -eq "0" ]] || [[ ${TXT_OR_BIN} -eq "2" ]]; then
                    mkdir -p "$CUT_DIR/txts"
                    mv *.txt "$CUT_DIR/txts/" && echo -e "${GREEN}[OK]${NC} Arquivos de texto movidos"
                fi

                # Plotting
                #echo -e "${BOLD}${BLUE}[PLOT]${NC} Gerando gráficos..."
                TMP_GS=$(mktemp)
                trap 'rm -f "$TMP_GS"' EXIT

                sed -e "s|<CTL>|$ARQ_CTL_OUT|g" \
                    -e "s|<VAR>|$VAR|g" \
                    -e "s|<CUT_LINE>|$CUT_LINE|g" \
                    -e "s|<SEASON>|$SEASON|g" \
                    -e "s|<PERC>|$PERCENTAGE|g" \
                    -e "s|<NOME_FIG>|${ARQ_BIN_OUT}_${SEASON}|g" \
                    "$SCRIPT_DIR/src/gs/gs" > "$TMP_GS"

                if grads -blc "run $TMP_GS"; then
                    echo -e "${GREEN}[SUCESSO]${NC} Gráficos gerados com sucesso"
                else
                    echo -e "${RED}[FALHA]${NC} Erro na geração dos gráficos"
                    exit 1
                fi
                
                echo -e "${GRAY}─────────────────────────────────────────${NC}"
            done
        done
    done
    
    echo -e "${GREEN}[CONCLUÍDO]${NC} Processamento finalizado para ${CYAN}$(basename "$CTL_FILE")${NC}\n"
done

echo -e "${GREEN}${BOLD}=== Processamento completo! ===${NC}"