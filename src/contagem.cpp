// Implementado por Eduardo Machado
// 2016

#include <iostream>
#include <string>
#include <fstream>
#include <map>
#include <cstdlib>
#include <cmath>
#include <vector>

using namespace std;

string toUpper(string str) {
    for (char& c : str)
        c = toupper(c);
    return str;
}

int main(int argc, char *argv[]){
  // Arquivos de entrada e saída
  ifstream fileIn;
	ofstream fileOutBin, fileOutTxt;
  // Parâmetros de entrada
  string nameFileIn, nameFileOut;
  int nx, ny, nz, nt, txtOrBin;
  float undef, cutLine, dataCutLine;
  // Demais variáveis do programa
  int i, j, k, l;       // Indices para trabalhar com as matrizes
  int undefCont;        // Contador de valores indefinidos
  bool zeroSentinel;    // booleano para dizer quando o gráfico passa pelo zero
  float ****inMatrix;   // matriz de entrada
  float ***outMatrix;   // matriz de saída

  // Leitura de parâmetros.
	if(argc != 11){
		cout << "Parâmetros errados!" << endl;
		return 0;
	}
	nameFileIn = argv[1];
	nx = atoi(argv[2]);
	ny = atoi(argv[3]);
	nz = atoi(argv[4]);
	nt = atoi(argv[5]);
	undef = atof(argv[6]);
	cutLine = atof(argv[7]);
	txtOrBin = atoi(argv[8]);
	nameFileOut = argv[9];
	dataCutLine = atof(argv[10]);
  // Alocação da matriz de entrada
  inMatrix = new float***[nx];
  outMatrix = new float**[nx];
  for(i=0;i<nx;i++){
    inMatrix[i] = new float**[ny];
    outMatrix[i] = new float*[ny];
    for(j=0;j<ny;j++){
      inMatrix[i][j] = new float*[nz];
      outMatrix[i][j] = new float[nz];
      for(k=0;k<nz;k++){
        inMatrix[i][j][k] = new float[nt];
      }
    }
  }
  // Abertura do arquivo de entrada.
	fileIn.open(nameFileIn.c_str(), ios::binary);
	fileIn.seekg (0);
  for(i=0;i<nt;i++){
    for(j=0;j<nz;j++){
      for(k=0;k<ny;k++){
        for(l=0;l<nx;l++){
          fileIn.read((char*)&inMatrix[l][k][j][i], sizeof(float));
          if(isnan(inMatrix[l][k][j][i])){
						inMatrix[l][k][j][i]=undef;
					}
        }
      }
    }
  }

  for(i=0;i<nx;i++){
    for(j=0;j<ny;j++){
      for(k=0;k<nz;k++){
        zeroSentinel = true;
        outMatrix[i][j][k] = 0;
        undefCont=0;
        for(l=0;l<nt;l++){
          if((inMatrix[i][j][k][l] <= cutLine) && zeroSentinel && (inMatrix[i][j][k][l] != undef)){
            outMatrix[i][j][k]++;
            zeroSentinel = false;
          }
          if((inMatrix[i][j][k][l] >= 0.0) && !zeroSentinel && (inMatrix[i][j][k][l] != undef)){
            zeroSentinel = true;
          }
          if(inMatrix[i][j][k][l] != undef){
            undefCont++;
          }
        }
        if(undefCont < nt*(dataCutLine/100)){
          outMatrix[i][j][k] = undef;
        }
      }
    }
  }

  // Escrita no arquivo de saída.
  if((txtOrBin == 0)||(txtOrBin == 2)){
		fileOutTxt.open((nameFileOut+"_ANO.txt").c_str(), ios::out);

    for(i=0;i<nz;i++){
  		for(j=ny-1;j>=0;j--){
  			for(k=0;k<nx;k++){
          if(outMatrix[k][j][i] == undef){
            fileOutTxt << "-- ";
          }else if(outMatrix[k][j][i] < 10){
            fileOutTxt << "0" << outMatrix[k][j][i] << " ";
          }else{
            fileOutTxt << outMatrix[k][j][i] << " ";
          }
  			}
        fileOutTxt << endl;
  		}
    }
  }
  if((txtOrBin == 1)||(txtOrBin == 2)){
    fileOutBin.open((nameFileOut+"_ANO.bin").c_str(), ios::binary);

    for(i=0;i<nz;i++){
  		for(j=0;j<ny;j++){
  			for(k=0;k<nx;k++){
          fileOutBin.write ((char*)&outMatrix[k][j][i], sizeof(float));
        }
      }
		}
  }

  fileOutTxt.close();
  fileOutBin.close();
  fileIn.close();
}
