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

# Define arrays for percentages
PERCENTAGES=(80)
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

# Function to determine CLEVS and CCOLORS based on INTERVALO and CUT_LINE
get_clevs() {
    local interval="$1"
    local cut_line="$2"

    # Define ranges for each cut line and interval combination
    declare -A ranges=(
        ["-2.0_1"]="0 40"      
        ["-2.0_3"]="0 30"      
        ["-2.0_6"]="0 20"        
        ["-2.0_9"]="0 10"       
        ["-2.0_12"]="0 10"      
        ["-2.0_24"]="0 10"      
        ["-2.0_48"]="0 10"      
        ["-2.0_60"]="0 10"      
        ["-1.5_1"]="0 80"     
        ["-1.5_3"]="0 50"     
        ["-1.5_6"]="0 40"      
        ["-1.5_9"]="0 30"      
        ["-1.5_12"]="0 30"     
        ["-1.5_24"]="0 20"      
        ["-1.5_48"]="0 10"      
        ["-1.5_60"]="0 10"      
        ["1.0_1"]="50 150"
        ["1.0_3"]="0 80"      
        ["1.0_6"]="0 60"      
        ["1.0_9"]="0 50"      
        ["1.0_12"]="0 40"      
        ["1.0_24"]="0 30"      
        ["1.0_48"]="0 20"      
        ["1.0_60"]="0 20"      
        ["2.0_1"]="0 40"       
        ["2.0_3"]="0 30"       
        ["2.0_6"]="0 20"       
        ["2.0_9"]="0 20"       
        ["2.0_12"]="0 20"      
        ["2.0_24"]="0 10"      
        ["2.0_48"]="0 10"      
        ["2.0_60"]="0 10"      
    )

    local key="${cut_line}_${interval}"
    if [[ -n "${ranges[$key]}" ]]; then
        local min max
        read min max <<< "${ranges[$key]}"
        # Always keep start and end values, divide remaining range into 8 equal parts
        local step=$(( (max - min) / 8 ))
        echo -n "$min "
        for i in $(seq 1 7); do
            echo -n "$(( min + i * step )) "
        done
        echo "$max"
    else
        echo "0 2 4 6 8 10 12 14 16 18" # fallback values
    fi
}

get_colors() {
    echo "70 4 11 5 12 8 27 2"
}

INPUT_PATH="$1"
TXT_OR_BIN="${2:-1}"  # Default to 1 if not specified

# Create output directory structure
BASE_OUTPUT_DIR="$PWD/output/contagem/$(basename $INPUT_PATH)"
FIGURES_DIR="$BASE_OUTPUT_DIR/figures"
mkdir -p "$BASE_OUTPUT_DIR"

# Process input path
if [ -f "$INPUT_PATH" ] && [[ "$INPUT_PATH" == *.ctl ]]; then
    # Single file processing
    CTL_FILES=("$INPUT_PATH")
else
    # Directory processing
    CTL_FILES=("$INPUT_PATH"/*.ctl)
fi

echo -e "${GREEN}${BOLD}=== Iniciando operação ===${NC}"
echo -e "${BLUE}[CONFIG]${NC} Percentuais: ${PERCENTAGES[@]}"
echo -e "${BLUE}[CONFIG]${NC} Linhas de corte: ${CUT_LINES[@]}"
echo -e "${BLUE}[CONFIG]${NC} Tipo de saída: ${TXT_OR_BIN}"
echo -e "${BLUE}[CONFIG]${NC} Diretório de entrada: ${INPUT_PATH}"
echo -e "${BLUE}[CONFIG]${NC} Diretório de saída: ${BASE_OUTPUT_DIR}"

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
    for PERCENTAGE in "${PERCENTAGES[@]}"; do
        for CUT_LINE in "${CUT_LINES[@]}"; do
            echo -e "${BLUE}[CONFIG]${NC} Percentual: ${YELLOW}$PERCENTAGE%${NC}, Linha de Corte: ${YELLOW}$CUT_LINE${NC}"

            # Create percentage directory
            PERC_DIR="$FILE_OUTPUT_DIR/$PERCENTAGE"
            mkdir -p "$PERC_DIR"

            # Create cut line directory
            CUT_DIR="$PERC_DIR/${CUT_LINE/./_}"
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
            ARQ_CTL_OUT="$CUT_DIR/$(basename $ARQ_CTL_IN .ctl)_${CUT_LINE}.ctl"

            # Execute contagem program
            #echo -e "${BOLD}${BLUE}[EXECUÇÃO]${NC} Iniciando programa contagem..."
            if $SCRIPT_DIR/bin/contagem ${ARQ_BIN_IN} ${NX} ${NY} ${NZ} ${NT} ${UNDEF} ${CUT_LINE} ${TXT_OR_BIN} ${ARQ_BIN_OUT} ${PERCENTAGE}; then
                echo -e "${GREEN}[SUCESSO]${NC} Programa contagem executado com sucesso"
            else
                echo -e "${RED}[FALHA]${NC} Erro na execução do programa contagem"
                exit 1
            fi

            # Handle output files based on TXT_OR_BIN
            echo -e "${GRAY}[INFO]${NC} Processando arquivos de saída..."
            if [[ ${TXT_OR_BIN} -eq "1" ]] || [[ ${TXT_OR_BIN} -eq "2" ]]; then
                cp $ARQ_CTL_IN $ARQ_CTL_OUT
                sed -i "s#$(basename $ARQ_BIN_IN .bin)#$(basename ${ARQ_BIN_OUT} .bin)#g" ${ARQ_CTL_OUT}
                sed -i -E "s/^tdef[[:space:]]+[0-9]+/tdef 1/I" ${ARQ_CTL_OUT}
                #echo -e "${GREEN}[OK]${NC} Arquivos binários processados"
            fi

            if [[ ${TXT_OR_BIN} -eq "0" ]] || [[ ${TXT_OR_BIN} -eq "2" ]]; then
                mkdir -p "$CUT_DIR/txts"
                if ls *.txt 1>/dev/null 2>&1; then
                    mv *.txt "$CUT_DIR/txts/"
                else
                    echo -e "${BLUE}Não há arquivos .txt para mover${NC}"
                fi
            fi

            # Plotting
            TMP_GS=$(mktemp)
            trap 'rm -f "$TMP_GS"' EXIT

            # Calcular coordenadas da grade
            XDEF_LINE="$(grep -i '^xdef ' "$CTL_FILE" | head -n1)"
            YDEF_LINE="$(grep -i '^ydef ' "$CTL_FILE" | head -n1)"

            LONI="$(echo "$XDEF_LINE" | awk '{print $4}')"
            LON_DELTA="$(echo "$XDEF_LINE" | awk '{print $5}')"
            NXDEF="$(echo "$XDEF_LINE" | awk '{print $2}')"
            LONF=$(awk -v start="$LONI" -v delta="$LON_DELTA" -v n="$NXDEF" 'BEGIN {print start + (n-1)*delta}')

            LATI="$(echo "$YDEF_LINE" | awk '{print $4}')"
            LAT_DELTA="$(echo "$YDEF_LINE" | awk '{print $5}')"
            NYDEF="$(echo "$YDEF_LINE" | awk '{print $2}')"
            LATF=$(awk -v start="$LATI" -v delta="$LAT_DELTA" -v n="$NYDEF" 'BEGIN {print start + (n-1)*delta}')

            if [ "$(echo "$LATI > $LATF" | bc -l)" -eq 1 ]; then
                TMP="$LATI"
                LATI="$LATF"
                LATF="$TMP"
            fi

            # Modificação da extração do SPI
            # Tenta obter o valor de SPI do arquivo CTL
            SPI=$(grep -i "spi[[:space:]]*=" "$ARQ_CTL_IN" | head -n 1 | awk -F'=' '{print $2}' | tr -d '"' | tr -d ' ')

            # Se não encontrar no arquivo, tenta extrair do nome do arquivo
            if [ -z "$SPI" ]; then
                echo -e "${GRAY}[INFO]${NC} SPI não encontrado no arquivo CTL. Tentando extrair do nome do arquivo..."
                SPI=$(basename "$ARQ_CTL_IN" | grep -o -P 'spi\K[0-9]+|spi=\K[0-9]+')
                if [ -z "$SPI" ]; then
                    echo -e "${YELLOW}[AVISO]${NC} Não foi possível extrair SPI do arquivo CTL ou do nome do arquivo."
                    SPI=""  # valor padrão caso não encontre
                fi
            fi

            CINT=$(get_clevs $SPI $CUT_LINE)
            CCOLORS=$(get_colors)

            echo -e "${GRAY}[INFO]${NC} Gerando gráficos..."
            echo -e "${BLUE}[CONFIG]${NC} LONI: $LONI, LONF: $LONF, LATI: $LATI, LATF: $LATF"
            echo -e "${BLUE}[CONFIG]${NC} SPI: $SPI, CINT: $CINT, CCOLORS: $CCOLORS"

            sed -e "s|<CTL>|$ARQ_CTL_OUT|g" \
                -e "s|<VAR>|$VAR|g" \
                -e "s|<CUT_LINE>|$CUT_LINE|g" \
                -e "s|<SPI>|$SPI|g" \
                -e "s|<PERC>|$PERCENTAGE|g" \
                -e "s|<NOME_FIG>|${ARQ_BIN_OUT}|g" \
                -e "s|<CINT>|$CINT|g" \
                -e "s|<CCOLORS>|$CCOLORS|g" \
                -e "s|<BOTTOM>|$(basename ${CTL_FILE})|g" \
                -e "s|<LATI>|$LATI|g" \
                -e "s|<LATF>|$LATF|g" \
                -e "s|<LONI>|$LONI|g" \
                -e "s|<LONF>|$LONF|g" \
                "$SCRIPT_DIR/src/gs/gs" > "$TMP_GS"

            if grads -pbc "run $TMP_GS"; then
                echo -e "${GREEN}[SUCESSO]${NC} Gráficos gerados com sucesso"
            else
                echo -e "${RED}[FALHA]${NC} Erro na geração dos gráficos"
                exit 1
            fi
            
            mkdir -p "$FIGURES_DIR/$PERCENTAGE/$CUT_LINE"
            cp $ARQ_BIN_OUT.png $FIGURES_DIR/$PERCENTAGE/$CUT_LINE/$(basename $ARQ_BIN_OUT).png

            echo -e "${GRAY}─────────────────────────────────────────${NC}"
        done
    done
    
    echo -e "${GREEN}[CONCLUÍDO]${NC} Processamento finalizado para ${CYAN}$(basename "$CTL_FILE")${NC}\n"
done

echo -e "${GREEN}${BOLD}=== Processamento completo! ===${NC}"