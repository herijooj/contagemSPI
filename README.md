# contagemSPI
Conta o número de eventos abaixo de uma linha de corte de um CTL

**Implementado por Eduardo Machado**  
**Ano: 2016**

**Alterações por:**
- **Heric Camargo**  
  **Ano: 2025**  
  **Detalhes:**
  - Makefile para compilação
  - Remoção de warnings e variáveis não utilizadas
  - Entrada de dados pelo terminal
  - Melhorias de qualidade de vida (Quality of Life improvements)

Este programa conta o número de eventos onde o índice de seca passa a baixo de uma linha de corte. 

## Visão Geral do Processo

O fluxo do programa é o seguinte:
1. **Entrada de Dados**: O programa lê um diretório de arquivos CTL. (ou um arquivo CTL)
2. **Cálculo**: O programa 'contagem.cpp' calcula o número de eventos abaixo de uma linha de corte.
3. **Saída de Dados**: A saída é um arquivo de texto, um binário e um CTL nos seus respectivos diretórios.
4. **Plotagem**: Também são plotados gráficos de saída usando o 'GrADS'.

## Requisitos
- **GrADS**: O GrADS é um software de visualização e análise de dados meteorológicos.
- **Compilador C++**: Você provavelmente já tem um instalado no seu sistema.
- **Biblioteca de Matemática**: Você provavelmente já tem uma instalada no seu sistema.

## Como usar

1. **Execução**:
   No terminal, execute o comando:

    ```bash
    ./contagemSPI.sh [DIRETORIO_OU_ARQUIVO_ENTRADA] [TXT_OU_BIN] [PERCENTAGES] [CUT_LINES]
    ```

    > **Atenção**: Este script deve ser executado na **Chagos**. Ele não funciona na minha máquina local.

    Substitua:
    - `[DIRETORIO_OU_ARQUIVO_ENTRADA]` pelo diretório ou arquivo de entrada.
    - `[TXT_OU_BIN]` pelo tipo de saída desejada. (se vazio, os dois)
    - `[PERCENTAGES]` pelo valor da linha de corte. (se vazio, 70% e 80%)
    - `[CUT_LINES]` pelo valor da linha de corte. (se vazio, -2.0 -1.5 1.0 2.0)

    Rodadas:
    Para cada arquivo CTL, todas as linhas de corte e porcentagens são calculadas para cada uma das estações:
    - DJF (Dezembro, Janeiro, Fevereiro)
    - MAM (Março, Abril, Maio)
    - JJA (Junho, Julho, Agosto)
    - SON (Setembro, Outubro, Novembro)
    - ANO (Anual)

## Exemplo

```bash
(base) hericcamargo@chagos:~/contagemSPI$ ./contagem_spi.sh 
ERRO! Parametros errados! Utilize:
script.sh [DIRETORIO_OU_ARQUIVO_ENTRADA] [TXT_OU_BIN]

 - TXT_OU_BIN = 0, cria arquivo texto com os resultados.
 - TXT_OU_BIN = 1, cria arquivo binário e controle com resultados (padrão).
 - TXT_OU_BIN = 2, cria os dois tipos de arquivos.
```

2. **Saída**:
   Para um diretório com os arquivos CTL de entrada como:

```bash
.
├── dado_composto_ams_mensal_lab+gpcc_spi12.bin
├── dado_composto_ams_mensal_lab+gpcc_spi12.ctl
├── dado_composto_ams_mensal_lab+gpcc_spi24.bin
├── dado_composto_ams_mensal_lab+gpcc_spi24.ctl
├── dado_composto_ams_mensal_lab+gpcc_spi3.bin
├── dado_composto_ams_mensal_lab+gpcc_spi3.ctl
├── dado_composto_ams_mensal_lab+gpcc_spi48.bin
├── dado_composto_ams_mensal_lab+gpcc_spi48.ctl
├── dado_composto_ams_mensal_lab+gpcc_spi60.bin
├── dado_composto_ams_mensal_lab+gpcc_spi60.ctl
├── dado_composto_ams_mensal_lab+gpcc_spi6.bin
└── dado_composto_ams_mensal_lab+gpcc_spi6.ctl
```

A saída será:

```bash
.
├── composto_0.5_mensal_ams_lab+gpcc_spi1
│   ├── ANO / DJF / JJA / MAM / SON
│   │   ├── perc_70 / perc_80
│   │   │   ├── cut_1_0 / cut_2_0 / cut_-1_5 / cut_-2_0
│   │   │   │   ├── composto_0.5_mensal_ams_lab+gpcc_spi1_1.0_ANO.bin # Arquivo binário
│   │   │   │   ├── composto_0.5_mensal_ams_lab+gpcc_spi1_1.0_ANO.ctl # Arquivo CTL
│   │   │   │   └── composto_0.5_mensal_ams_lab+gpcc_spi1_1.0_ANO.png # Gráfico
│   │   │   └── ...
│   │   ├── ...
│   │   └── ...
│   ├── ...
│   └── ...
├── ...
└── ...
```

## Melhorias Futuras
1. **Paralelização**: Paralelizar o cálculo do tempo característico para acelerar o processo.
