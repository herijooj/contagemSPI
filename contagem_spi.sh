#!/bin/bash

# Implementado por Eduardo Machado
# 2016

#2023
# Lucas Nogueira: alteração nos `greps`, último `sed` e caminho dos arquivos

if [[ $# != 5 ]]; then
	echo ""
	echo "ERRO! Parametros errados! Utilize:"
	echo "contagem_spi [ARQ_CTL_ENTRADA] [LINHA_DE_CORTE] [TXT_OU_BIN] [ESTACAO] [% DADOS]"
	echo
	echo " - TXT_OU_BIN = 0, cria arquivo texto com os resultados."
	echo " - TXT_OU_BIN = 1, cria arquivo binário e controle com resultados."
	echo " - TXT_OU_BIN = 2, cria os dois tipos de arquivos."
	echo
    echo " - ESTACAO = 'ano','ver','out','inv' ou 'pri'."
    echo
	echo " - % DADOS = Número entre 0 e 100"
	echo
else
	ARQ_CTL_IN=${1}
	CUT_LINE=${2}
	TXT_OR_BIN=${3}
	SEASON=${4}
	PERCENTUAL_DADOS=${5}

    
    #pega o nome do arquivo binario (pode ou não ter um caminho de arquivo junto)
    ARQ_BIN_IN="$(grep -i -w '^dset' $ARQ_CTL_IN | xargs | cut -d" " -f2)"

    # Se o nome do arquivo começa com '^', troca '^' pelo diretório do ctl
    if [ "${ARQ_BIN_IN:0:1}" = "^" ]
    then 
        ARQ_BIN_IN="$(dirname $ARQ_CTL_IN)/$(basename ${ARQ_BIN_IN:1})"
    fi  

    # Retira as variáveis necessárias para a execução                                                                                             
    NX=$(grep -i -w '^xdef' ${ARQ_CTL_IN} | xargs | cut -d" " -f2)
    NY=$(grep -i -w '^ydef' ${ARQ_CTL_IN} | xargs | cut -d" " -f2)
    NZ=$(grep -i -w '^zdef' ${ARQ_CTL_IN} | xargs | cut -d" " -f2)
    NT=$(grep -i -w '^tdef' ${ARQ_CTL_IN} | xargs | cut -d" " -f2)
    UNDEF=$(grep -i -w '^undef' ${ARQ_CTL_IN}| xargs | cut -d" " -f2)


	# arquivos serão salvos no diretório atual
    ARQ_BIN_OUT="$(basename $ARQ_BIN_IN .bin)_${CUT_LINE}"
    ARQ_CTL_OUT="$(basename $ARQ_CTL_IN .ctl)_${CUT_LINE}_${SEASON}.ctl"
    
    echo ${ARQ_BIN_IN} ${NX} ${NY} ${NZ} ${NT} ${UNDEF} ${CUT_LINE} ${TXT_OR_BIN} ${SEASON} ${ARQ_BIN_OUT} ${PERCENTUAL_DADOS}	# Imprime os parâmetros que estão sendo usados

	# Executa o programa
	/geral/programas/contagem_SPI/bin/contagem ${ARQ_BIN_IN} ${NX} ${NY} ${NZ} ${NT} ${UNDEF} ${CUT_LINE} ${TXT_OR_BIN} ${SEASON} ${ARQ_BIN_OUT} ${PERCENTUAL_DADOS}
	
    if [[ ${TXT_OR_BIN} -eq "1" ]]; then
		
		cp $ARQ_CTL_IN $ARQ_CTL_OUT
		
        sed -i "s#$(basename $ARQ_BIN_IN .bin)#$(basename ${ARQ_BIN_OUT}_${SEASON} .bin)#g" ${ARQ_CTL_OUT}
        sed -i -E "s/^tdef[[:space:]]+[0-9]+/tdef 1/I" ${ARQ_CTL_OUT}

	elif [[ ${TXT_OR_BIN} -eq "2" ]]; then
		
		cp $ARQ_CTL_IN $ARQ_CTL_OUT
		
        sed -i "s#$(basename $ARQ_BIN_IN .bin)#$(basename ${ARQ_BIN_OUT}_${SEASON} .bin)#g" ${ARQ_CTL_OUT}
        sed -i -E "s/^tdef[[:space:]]+[0-9]+/tdef 1/I" ${ARQ_CTL_OUT}
		
        if [ ! -d "txts" ]; then
			mkdir txts
		fi
		
        mv *.txt txts
	else
		if [ ! -d "txts" ]; then
			mkdir txts
		fi
		
        mv *.txt txts
	fi
fi
