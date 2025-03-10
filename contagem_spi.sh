#!/bin/bash

# Implementado por Eduardo Machado (2016)
# Modified by Lucas Nogueira (2023)
# Modified by Heric Camargo (2025)

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
NC2BIN="/geral/programas/converte_nc_bin/converte_dados_nc_to_bin.sh"

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

print_bar() {
    local color=$1
    local text=$2
    local width=$(tput cols)
    local text_len=${#text}
    local pad_len=$(( (width - text_len - 2) / 2 ))
    local padding=$(printf '%*s' $pad_len '')
    echo -e "${color}${padding// /=} ${text} ${padding// /=}=${NC}"
}

# Define arrays for percentages
PERCENTAGES=(80)
CUT_LINES=(-2.0 -1.5 1.0 2.0)

# Check if input parameters are provided
if [ "$#" -lt 1 ]; then
    echo -e "${RED}ERRO! Nenhum parâmetro fornecido! Utilize:${NC}"
    echo -e "${YELLOW}script.sh [DIRETORIOS_OU_ARQUIVOS_ENTRADA...] [TXT_OU_BIN]${NC}"
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

# Check if the last argument is a number (representing TXT_OR_BIN)
last_arg="${@: -1}"
if [[ "$last_arg" =~ ^[0-2]$ ]]; then
    TXT_OR_BIN="$last_arg"
    # Remove the last argument from the list
    set -- "${@:1:$#-1}"
else
    # Default to 1 if last argument is not a valid TXT_OR_BIN value
    TXT_OR_BIN="1"
fi

# The remaining arguments are input paths
INPUT_PATHS=("$@")

echo -e "${GREEN}${BOLD}=== Iniciando operação ===${NC}"
echo -e "${BLUE}[CONFIG]${NC} Percentuais: ${PERCENTAGES[@]}"
echo -e "${BLUE}[CONFIG]${NC} Linhas de corte: ${CUT_LINES[@]}"
echo -e "${BLUE}[CONFIG]${NC} Tipo de saída: ${TXT_OR_BIN}"
echo -e "${BLUE}[CONFIG]${NC} Total de entradas: ${#INPUT_PATHS[@]}"

# Process each input path
for INPUT_PATH in "${INPUT_PATHS[@]}"; do
    echo -e "\n${BOLD}${PURPLE}=== Processando entrada: ${CYAN}${INPUT_PATH}${NC} ===\n"

    # Create output directory for this input
    BASE_OUTPUT_DIR="$PWD/output/contagem/$(basename $INPUT_PATH)"
    FIGURES_DIR="$BASE_OUTPUT_DIR/figures"
    mkdir -p "$BASE_OUTPUT_DIR"
    
    echo -e "${BLUE}[CONFIG]${NC} Diretório de entrada: ${INPUT_PATH}"
    echo -e "${BLUE}[CONFIG]${NC} Diretório de saída: ${BASE_OUTPUT_DIR}"

    # Process input path
    if [ -f "$INPUT_PATH" ] && [[ "$INPUT_PATH" == *.ctl ]]; then
        # Single file processing
        CTL_FILES=("$INPUT_PATH")
    else
        # Directory processing
        CTL_FILES=("$INPUT_PATH"/*.ctl)
    fi

    # Check if any .ctl files found
    if [ ${#CTL_FILES[@]} -eq 0 ] || [ ! -f "${CTL_FILES[0]}" ]; then
        echo -e "${RED}[ERRO]${NC} Nenhum arquivo .ctl encontrado em $INPUT_PATH"
        continue  # Skip to next input path instead of exiting
    fi

    # Process each .ctl file
    for CTL_FILE in "${CTL_FILES[@]}"; do
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
                ARQ_BIN_OUT="$CUT_DIR/$(basename $ARQ_BIN_IN .bin)_${CUT_LINE}_cont"
                ARQ_CTL_OUT="$CUT_DIR/$(basename $ARQ_CTL_IN .ctl)_${CUT_LINE}_cont.ctl"

                # Execute contagem program
                if $SCRIPT_DIR/bin/contagem ${ARQ_BIN_IN} ${NX} ${NY} ${NZ} ${NT} ${UNDEF} ${CUT_LINE} ${TXT_OR_BIN} ${ARQ_BIN_OUT} ${PERCENTAGE}; then
                    echo -e "${GREEN}[SUCESSO]${NC} Programa contagem executado com sucesso"
                else
                    echo -e "${RED}[FALHA]${NC} Erro na execução do programa contagem"
                    continue  # Skip to next combination instead of exiting
                fi

                # Handle output files based on TXT_OR_BIN
                echo -e "${GRAY}[INFO]${NC} Processando arquivos de saída..."
                if [[ ${TXT_OR_BIN} -eq "1" ]] || [[ ${TXT_OR_BIN} -eq "2" ]]; then
                    cp $ARQ_CTL_IN $ARQ_CTL_OUT
                    sed -i "s#$(basename $ARQ_BIN_IN .bin)#$(basename ${ARQ_BIN_OUT} .bin)#g" ${ARQ_CTL_OUT}
                    sed -i -E "s/^tdef[[:space:]]+[0-9]+/tdef 1/I" ${ARQ_CTL_OUT}
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
                TITLE="Contagem | SPI${SPI} | ${CUT_LINE}"
                BOTTOM=$(basename "$CTL_FILE")

                echo -e "${GRAY}[INFO]${NC} Gerando gráficos..."
                echo -e "${BLUE}[CONFIG]${NC} LONI: $LONI, LONF: $LONF, LATI: $LATI, LATF: $LATF"
                echo -e "${BLUE}[CONFIG]${NC} SPI: $SPI, CINT: $CINT, CCOLORS: $CCOLORS"

                sed -e "s|<CTL>|$ARQ_CTL_OUT|g" \
                    -e "s|<VAR>|$VAR|g" \
                    -e "s|<CUT_LINE>|$CUT_LINE|g" \
                    -e "s|<SPI>|$SPI|g" \
                    -e "s|<PERC>|$PERCENTAGE|g" \
                    -e "s@<TITLE>@$TITLE@g" \
                    -e "s|<NOME_FIG>|${ARQ_BIN_OUT}|g" \
                    -e "s|<CINT>|$CINT|g" \
                    -e "s|<CCOLORS>|$CCOLORS|g" \
                    -e "s|<BOTTOM>|$BOTTOM|g" \
                    -e "s|<LATI>|$LATI|g" \
                    -e "s|<LATF>|$LATF|g" \
                    -e "s|<LONI>|$LONI|g" \
                    -e "s|<LONF>|$LONF|g" \
                    "$SCRIPT_DIR/src/gs/gs" > "$TMP_GS"

                if grads -pbc "run $TMP_GS"; then
                    echo -e "${GREEN}[SUCESSO]${NC} Gráficos gerados com sucesso"
                else
                    echo -e "${RED}[FALHA]${NC} Erro na geração dos gráficos"
                    # Continue instead of exiting to process other combinations
                    continue
                fi
                
                mkdir -p "$FIGURES_DIR/$PERCENTAGE/$CUT_LINE"
                cp $ARQ_BIN_OUT.png $FIGURES_DIR/$PERCENTAGE/$CUT_LINE/$(basename $ARQ_BIN_OUT).png

                echo -e "${GRAY}─────────────────────────────────────────${NC}"
            done
        done
        
        echo -e "${GREEN}[CONCLUÍDO]${NC} Processamento finalizado para ${CYAN}$(basename "$CTL_FILE")${NC}\n"
    done
    
    print_bar "${GREEN}" "CONCLUÍDO: Processamento finalizado para entrada ${INPUT_PATH}"
done

# Função para detectar padrão de nomes e criar nome do ensemble
generate_ensemble_name() {
    local input_paths=("$@")
    local ensemble_name=""
    
    # Verifica se todas as pastas têm um padrão de nome similar (ex: EC-Earth3_ssp245_r1_gr_2027-2100)
    # Pega o primeiro diretório como referência
    local first_dir=$(basename "${input_paths[0]}")
    
    # Tenta encontrar padrão "rN" onde N é um número
    if [[ "$first_dir" =~ _r[0-9]+_ ]]; then
        # Extrai o prefixo e sufixo antes e depois do padrão rN
        local common_prefix="${first_dir%%_r[0-9]*}"
        local common_suffix="${first_dir#*_r[0-9]_}"
        ensemble_name="${common_prefix}_Ensemble_${common_suffix}"
    else
        # Se não encontrar o padrão, usa "Ensemble" como nome base
        ensemble_name="Ensemble_$(date +%Y%m%d)"
    fi
    
    echo "$ensemble_name"
}

# Função para calcular o ensemble mean
calculate_ensemble_mean() {
    local output_base_dir="$PWD/output/contagem"
    local input_paths=("$@")
    local ensemble_name=$(generate_ensemble_name "${input_paths[@]}")
    
    print_bar "${PURPLE}" "CALCULANDO ENSEMBLE MEAN"
    echo -e "${BLUE}[INFO]${NC} Nome do ensemble: ${ensemble_name}"
    
    # Cria diretório para o ensemble
    local ensemble_dir="${output_base_dir}/${ensemble_name}"
    mkdir -p "${ensemble_dir}" || { echo -e "${RED}[ERRO]${NC} Falha ao criar diretório do ensemble ${ensemble_dir}"; return 1; }
    
    # Para cada percentual e linha de corte, calcular o ensemble
    for PERCENTAGE in "${PERCENTAGES[@]}"; do
        for CUT_LINE in "${CUT_LINES[@]}"; do
            echo -e "\n${BOLD}${PURPLE}=== Processando Ensemble para ${YELLOW}$PERCENTAGE%${NC}, ${YELLOW}Linha de Corte: $CUT_LINE${NC} ===${NC}"
            
            # Primeiro, identifica todos os SPIs disponíveis nos diretórios de entrada
            local available_spis=()
            
            for input_path in "${input_paths[@]}"; do
                local model_dir="${output_base_dir}/$(basename ${input_path})"
                for ctl_file in $(find "${model_dir}" -path "*/${PERCENTAGE}/${CUT_LINE/./_}/*.ctl" -type f 2>/dev/null); do
                    if [[ -f "$ctl_file" ]]; then
                        # Tenta extrair o SPI do nome do arquivo
                        if [[ "$(basename ${ctl_file})" =~ spi([0-9]+)_ ]]; then
                            local spi="${BASH_REMATCH[1]}"
                            # Adiciona à lista se ainda não estiver lá
                            if ! [[ " ${available_spis[@]} " =~ " ${spi} " ]]; then
                                available_spis+=("$spi")
                            fi
                        fi
                    fi
                done
            done
            
            if [ ${#available_spis[@]} -eq 0 ]; then
                echo -e "${YELLOW}[AVISO]${NC} Nenhum SPI identificado para percentual ${PERCENTAGE}% e linha de corte ${CUT_LINE}"
                continue
            fi
            
            echo -e "${BLUE}[INFO]${NC} SPIs identificados: ${available_spis[@]}"
            
            # Para cada SPI encontrado, cria um ensemble específico
            for spi_value in "${available_spis[@]}"; do
                echo -e "\n${BOLD}${PURPLE}=== Calculando Ensemble para SPI${spi_value}, ${YELLOW}$PERCENTAGE%${NC}, ${YELLOW}Linha de Corte: $CUT_LINE${NC} ===${NC}"
                
                # Cria subdiretórios para o percentual, linha de corte e SPI atual
                local perc_dir="${ensemble_dir}/${PERCENTAGE}"
                local cut_dir="${perc_dir}/${CUT_LINE/./_}"
                local figures_dir="${ensemble_dir}/figures/${PERCENTAGE}/${CUT_LINE}"
                mkdir -p "${cut_dir}" "${figures_dir}"
                
                # Prepara lista de arquivos para o CDO ensmean, específicos para este SPI
                local nc_files=()
                local temp_dir=$(mktemp -d)
                trap 'rm -rf "$temp_dir"' EXIT
                
                # Encontra arquivos CTL específicos para este SPI
                for input_path in "${input_paths[@]}"; do
                    local model_dir="${output_base_dir}/$(basename ${input_path})"
                    
                    # Procura apenas por arquivos com o SPI específico
                    for ctl_file in $(find "${model_dir}" -path "*/${PERCENTAGE}/${CUT_LINE/./_}/*spi${spi_value}_*.ctl" -type f 2>/dev/null); do
                        if [[ -f "$ctl_file" ]]; then
                            echo -e "${GRAY}[INFO]${NC} Processando arquivo SPI${spi_value}: $(basename ${ctl_file})"
                            
                            # Converte de .ctl para .nc usando CDO
                            local nc_out="${temp_dir}/$(basename ${input_path})_$(basename ${ctl_file} .ctl).nc"
                            echo -e "${GRAY}[INFO]${NC} Convertendo para NetCDF: ${nc_out}"
                            
                            if cdo -f nc import_binary "${ctl_file}" "${nc_out}" 2>/dev/null; then
                                nc_files+=("${nc_out}")
                            else
                                echo -e "${YELLOW}[AVISO]${NC} Falha ao converter ${ctl_file} para NetCDF"
                            fi
                        fi
                    done
                done
                
                # Verifica se encontrou arquivos para este SPI específico
                if [ ${#nc_files[@]} -eq 0 ]; then
                    echo -e "${YELLOW}[AVISO]${NC} Nenhum arquivo encontrado para SPI${spi_value}, percentual ${PERCENTAGE}% e linha de corte ${CUT_LINE}"
                    continue
                fi
                
                echo -e "${BLUE}[INFO]${NC} Calculando ensemble mean para ${#nc_files[@]} arquivos de SPI${spi_value}"
                
                # Determina o nome base para o arquivo de saída específico para este SPI
                local base_name=""
                if [[ -f "${nc_files[0]}" ]]; then
                    # Extrai o padrão comum do nome (removendo parte específica do run)
                    base_name=$(basename "${nc_files[0]}" .nc)
                    if [[ "$base_name" =~ _r[0-9]+_ ]]; then
                        # Remove o padrão _rN_ e usa como base para nome do ensemble
                        local prefix="${base_name%%_r[0-9]*}"
                        local suffix="${base_name#*_r[0-9]_*_}"
                        base_name="${prefix}_ensemble_${suffix}"
                    else
                        base_name="${base_name%%_*}_ensemble_spi${spi_value}_${CUT_LINE}_cont"
                    fi
                else
                    base_name="ensemble_spi${spi_value}_${PERCENTAGE}_${CUT_LINE/./_}_cont"
                fi
                
                # Calcula o ensemble mean usando CDO
                local temp_ensemble_nc="${temp_dir}/${base_name}.nc"
                local ensemble_bin="${cut_dir}/${base_name}"
                local ensemble_ctl="${cut_dir}/${base_name}.ctl"
                
                # Constrói e executa comando CDO para ensemble mean
                local cdo_cmd="cdo ensmean"
                for nc_file in "${nc_files[@]}"; do
                    cdo_cmd+=" ${nc_file}"
                done
                cdo_cmd+=" ${temp_ensemble_nc}"
                
                echo -e "${GRAY}[INFO]${NC} Executando: ${cdo_cmd}"
                if eval ${cdo_cmd}; then
                    echo -e "${GREEN}[OK]${NC} Ensemble mean calculado com sucesso para SPI${spi_value}"
                    
                    # Converte o resultado de volta para .ctl
                    if [ -f "${NC2BIN}" ]; then
                        echo -e "${GRAY}[INFO]${NC} Convertendo resultado para CTL/BIN"
                        if bash "${NC2BIN}" "${temp_ensemble_nc}" "${ensemble_ctl}"; then
                            echo -e "${GREEN}[OK]${NC} Convertido para CTL/BIN com sucesso"
                        else
                            echo -e "${RED}[ERRO]${NC} Falha ao converter ensemble NC para CTL/BIN"
                            continue
                        fi
                    else
                        echo -e "${YELLOW}[AVISO]${NC} Script de conversão NC2BIN não encontrado em ${NC2BIN}"
                        # Gera CTL usando CDO diretamente
                        cdo -f grads export_binary "${temp_ensemble_nc}" "${ensemble_bin}"
                    fi
                    
                    # Plot do resultado com GrADS
                    local tmp_gs=$(mktemp)
                    
                    # Extrai parâmetros da grade do NetCDF
                    local dimensions=$(cdo griddes "${temp_ensemble_nc}" | grep -E "xsize|ysize|xfirst|yfirst|xinc|yinc")
                    local nx=$(echo "$dimensions" | grep "xsize" | awk '{print $3}')
                    local ny=$(echo "$dimensions" | grep "ysize" | awk '{print $3}')
                    local loni=$(echo "$dimensions" | grep "xfirst" | awk '{print $3}')
                    local lati=$(echo "$dimensions" | grep "yfirst" | awk '{print $3}')
                    local lon_delta=$(echo "$dimensions" | grep "xinc" | awk '{print $3}')
                    local lat_delta=$(echo "$dimensions" | grep "yinc" | awk '{print $3}')
                    
                    local lonf=$(awk -v start="$loni" -v delta="$lon_delta" -v n="$nx" 'BEGIN {print start + (n-1)*delta}')
                    local latf=$(awk -v start="$lati" -v delta="$lat_delta" -v n="$ny" 'BEGIN {print start + (n-1)*delta}')
                    
                    # Garante que lati < latf
                    if (( $(echo "$lati > $latf" | bc -l) )); then
                        local tmp="$lati"
                        lati="$latf"
                        latf="$tmp"
                    fi
                    
                    # Define CINT e CCOLORS para o plot
                    local cint=$(get_clevs $spi_value $CUT_LINE)
                    local ccolors=$(get_colors)
                    
                    # Determina a variável do NetCDF
                    local var_name=$(cdo showname "${temp_ensemble_nc}" | head -1)
                    
                    # Cria um BOTTOM mais consistente para o ensemble
                    # Extrai modelo e cenário do nome do ensemble
                    local model_scenario=""
                    if [[ "${ensemble_name}" =~ ^([A-Za-z0-9\+-]+_[A-Za-z0-9\+-]+)_ ]]; then
                        model_scenario="${BASH_REMATCH[1]}"
                    else
                        model_scenario="Ensemble"
                    fi
                    
                    # Verifica se há informação de resolução no nome
                    local resolution=""
                    if [[ "${base_name}" =~ _([gr][0-9n]+)_ ]]; then
                        resolution="_${BASH_REMATCH[1]}"
                    fi
                    
                    # Verifica se há informação de período no nome
                    local period=""
                    if [[ "${base_name}" =~ _([0-9]{4}-[0-9]{4})_ ]]; then
                        period="_${BASH_REMATCH[1]}"
                    fi
                    
                    # Constrói um BOTTOM limpo
                    local BOTTOM="${model_scenario}_ensemble${resolution}${period}"
                    #take any _rN_ from the name
                    BOTTOM=$(echo "$BOTTOM" | sed -E 's/_r[0-9]+_//g')
                    echo -e "${BLUE}[INFO]${NC} BOTTOM: ${BOTTOM}"

                    TITLE="Contagem | SPI${spi_value} | ${CUT_LINE} | Ensemble Mean"

                    # Prepara o script GrADS
                    sed -e "s|<CTL>|$ensemble_ctl|g" \
                        -e "s|<VAR>|$var_name|g" \
                        -e "s|<CUT_LINE>|$CUT_LINE|g" \
                        -e "s|<SPI>|$spi_value|g" \
                        -e "s|<PERC>|$PERCENTAGE|g" \
                        -e "s@<TITLE>@$TITLE@g" \
                        -e "s|<NOME_FIG>|${ensemble_bin}|g" \
                        -e "s|<CINT>|$cint|g" \
                        -e "s|<CCOLORS>|$ccolors|g" \
                        -e "s|<BOTTOM>|$BOTTOM|g" \
                        -e "s|<LATI>|$lati|g" \
                        -e "s|<LATF>|$latf|g" \
                        -e "s|<LONI>|$loni|g" \
                        -e "s|<LONF>|$lonf|g" \
                        "$SCRIPT_DIR/src/gs/gs" > "$tmp_gs"
                    
                    echo -e "${GRAY}[INFO]${NC} Gerando gráfico do ensemble para SPI${spi_value}"
                    if grads -pbc "run $tmp_gs"; then
                        echo -e "${GREEN}[OK]${NC} Gráfico do ensemble gerado com sucesso para SPI${spi_value}"
                        cp ${ensemble_bin}.png ${figures_dir}/$(basename ${ensemble_bin}).png
                    else
                        echo -e "${RED}[ERRO]${NC} Falha na geração do gráfico do ensemble para SPI${spi_value}"
                    fi
                    
                    rm -f "$tmp_gs"
                else
                    echo -e "${RED}[ERRO]${NC} Falha ao calcular ensemble mean para SPI${spi_value}"
                fi
                
                echo -e "${GRAY}─────────────────────────────────────────${NC}"
            done # fim do loop para cada SPI
        done # fim do loop para cada linha de corte
    done # fim do loop para cada percentual
    
    print_bar "${GREEN}" "ENSEMBLE MEAN CONCLUÍDO"
}

# Verifica se há mais de uma entrada para calcular o ensemble
if [ ${#INPUT_PATHS[@]} -gt 1 ]; then
    echo -e "\n${BOLD}${GREEN}=== Calculando ensemble para múltiplas entradas ===${NC}"
    calculate_ensemble_mean "${INPUT_PATHS[@]}"
else
    echo -e "\n${YELLOW}[INFO]${NC} Apenas uma entrada fornecida - ensemble mean não será calculado."
fi

print_bar "${GREEN}" "= = = Processamento completo para todas as entradas! = = ="
