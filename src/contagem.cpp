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
  float ****inMatrix;   // matriz de entrada
  float ***outMatrix;   // matriz de saída
  float ****outMatrixMensal; // matriz de saída
  int eventCont, eventContMensal;
  bool abaixoCutline;

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
  outMatrixMensal = new float***[nx];
  for(i=0;i<nx;i++){
    inMatrix[i] = new float**[ny];
    outMatrix[i] = new float*[ny];
    outMatrixMensal[i] = new float**[ny];
    for(j=0;j<ny;j++){
      inMatrix[i][j] = new float*[nz];
      outMatrix[i][j] = new float[nz];
      outMatrixMensal[i][j] = new float*[nz];
      for(k=0;k<nz;k++){
        inMatrix[i][j][k] = new float[nt];
        outMatrixMensal[i][j][k] = new float[nt/12];
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
        abaixoCutline = false;
        outMatrix[i][j][k] = 0;
        eventCont = 0;
        eventContMensal = 0;
        undefCont = 0;
        for(l=0;l<nt;l++){
          if((inMatrix[i][j][k][l] <= cutLine) && (inMatrix[i][j][k][l] != undef)){
            if(!abaixoCutline) eventContMensal++;
            abaixoCutline = true;
          } else if((inMatrix[i][j][k][l] > cutLine) && abaixoCutline){
            abaixoCutline = false;
            eventCont++;
          }
          if((l+1) % 12 == 0){
            outMatrixMensal[i][j][k][(l+1)/12 - 1] = eventContMensal;
            eventContMensal = 0;
          }
          if(inMatrix[i][j][k][l] != undef){
            undefCont++;
          }
        }
        if(abaixoCutline) eventCont++;
        if(undefCont <= (dataCutLine/100)*nt){
          outMatrix[i][j][k] = undef;
        } else if(eventCont == 0){
          outMatrix[i][j][k] = 0.0;
        } else {
          outMatrix[i][j][k] = eventCont;
        }
        for(l=0; l<nt/12; l++){
          if(undefCont <= (dataCutLine/100)*nt){
            outMatrixMensal[i][j][k][l] = undef;
          }
        }
      }
    }
  }

  // Escrita no arquivo de saída.
  if((txtOrBin == 0)||(txtOrBin == 2)){
		fileOutTxt.open((nameFileOut+".txt").c_str(), ios::out);

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
    ofstream fileOutTxtMensal((nameFileOut+"_mensal.txt").c_str(), ios::out);
    for(l=0; l<nt/12; l++){
      fileOutTxtMensal << "Ano " << l+1 << ":" << endl << endl;
      for(i=0;i<nz;i++){
        for(j=ny-1;j>=0;j--){
          for(k=0;k<nx;k++){
            if(outMatrixMensal[k][j][i][l] == undef){
              fileOutTxtMensal << "-- ";
            } else if(outMatrixMensal[k][j][i][l] < 10){
              fileOutTxtMensal << "0" << outMatrixMensal[k][j][i][l] << " ";
            } else {
              fileOutTxtMensal << outMatrixMensal[k][j][i][l] << " ";
            }
          }
          fileOutTxtMensal << endl;
        }
      }
    }
    fileOutTxtMensal.close();
  }
  if((txtOrBin == 1)||(txtOrBin == 2)){
    fileOutBin.open((nameFileOut+".bin").c_str(), ios::binary);

    for(i=0;i<nz;i++){
  		for(j=0;j<ny;j++){
  			for(k=0;k<nx;k++){
          fileOutBin.write ((char*)&outMatrix[k][j][i], sizeof(float));
        }
      }
		}
    ofstream fileOutBinMensal((nameFileOut+"_mensal.bin").c_str(), ios::binary);
    for(l=0; l<nt/12; l++){
      for(k=0;k<nz;k++){
        for(j=0;j<ny;j++){
          for(i=0;i<nx;i++){
            fileOutBinMensal.write((char*)&outMatrixMensal[i][j][k][l], sizeof(float));
          }
        }
      }
    }
    fileOutBinMensal.close();
  }

  fileOutTxt.close();
  fileOutBin.close();
  fileIn.close();
}
