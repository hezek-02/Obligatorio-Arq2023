#include <stdio.h>
#include <stdlib.h>

//parametros globales
short AREA_DE_MEMORIA[2048];
const short VACIO = 0x8000;
short nodoDinamico = 0; //para parte dinámica
short modo; //indica modo estático o dinámico

//variables de menú
unsigned char eleccion ;
char continuarPrograma = 1;

//puertos
const short PUERTO_ENTRADA = 20;
const short PUERTO_SALIDA = 21;
const short PUERTO_LOG = 22;

//codigos de salida
const short CODIGO_EXITO = 0;
const short CODIGO_COMANDO_INVALIDO = 1;
const short CODIGO_PARAMETRO_INVALIDO = 2;
const short CODIGO_ESCRITURA_INVALIDA = 4;
const short CODIGO_NODO_EXISTENTE = 8;

void inicializar_memoria(){
    for (short i = 0; i < 2048; i++){
        AREA_DE_MEMORIA[i] = VACIO;
    }
}

//Modo estatico
void agregarNodo(short num, short nodo){ //insertarEnABB (2)
    if (nodo>=2048){
        outputPuertoLog(CODIGO_ESCRITURA_INVALIDA);
        return;
    }
    if (AREA_DE_MEMORIA[nodo] == VACIO){
        AREA_DE_MEMORIA[nodo] = num;
        outputPuertoLog(CODIGO_EXITO);
    }else{
        if(AREA_DE_MEMORIA[nodo]<num)
            agregarNodo(num, 2*(nodo+1));
        else if(AREA_DE_MEMORIA[nodo]>num)
            agregarNodo(num, 2*(nodo+1)-1);
        else
            outputPuertoLog(CODIGO_NODO_EXISTENTE);
    }
}

short calcularAltura(short nodo){ //imprime el ABb, 1 mayor a menor, 0 menor a mayor (3)
    if (nodo <= 2048 && AREA_DE_MEMORIA[nodo] != VACIO){
        short altIzquierda = calcularAltura(2*(nodo+1)-1) + 1;
        short altDerecha = calcularAltura(2*(nodo+1)) + 1;
        if (altDerecha > altIzquierda)
            return altDerecha;
        else
            return altIzquierda;
    }else
        return 0;
}

short calcularSuma(short nodo){ //Calcular suma (4)
    short suma = 0;
    if (nodo <= 2048 && AREA_DE_MEMORIA[nodo] != VACIO){
        suma = AREA_DE_MEMORIA[nodo] + calcularSuma(2*(nodo+1)) + calcularSuma(2*(nodo+1)-1);
    }
    return suma;
}

void imprimirArbol(short nodo, short orden){ //imprime el ABb, 1 mayor a menor, 0 menor a mayor (5)
    if (nodo <= 2048 && AREA_DE_MEMORIA[nodo] != VACIO){
        if (orden == 1 ){
            imprimirArbol(2*(nodo+1),orden);
            outputPuertoSalida(AREA_DE_MEMORIA[nodo]);      
            imprimirArbol(2*(nodo+1)-1,orden);
        }
        else if(orden == 0){
            imprimirArbol(2*(nodo+1)-1,orden);
            outputPuertoSalida(AREA_DE_MEMORIA[nodo]);      
            imprimirArbol(2*(nodo+1),orden);
        }
    }
}

void imprimirMemoria(short N){ //imprime el ABb, 1 mayor a menor, 0 menor a mayor (5)
    for (short i = 0; i < N; i++){//modo estático, donde cada posición supone simular
        outputPuertoSalida(AREA_DE_MEMORIA[i]);   
    }
}
//END Modo estático

//Modo dinámico
void agregarNodoDinamico(short num, short pos){
    if (pos > 2048/3){
        outputPuertoLog(CODIGO_ESCRITURA_INVALIDA);
        return;
    }
    if (AREA_DE_MEMORIA[pos] == VACIO) {
        if (pos == 0) {
            AREA_DE_MEMORIA[pos] = num;//nodo 0
        } else {
            nodoDinamico++;//incrementar nodo
            AREA_DE_MEMORIA[pos] = nodoDinamico;
            AREA_DE_MEMORIA[3*nodoDinamico] = num;
        }
        outputPuertoLog(CODIGO_EXITO);
    } else if (num < AREA_DE_MEMORIA[pos]) {
        if (AREA_DE_MEMORIA[pos+1] != VACIO)
            agregarNodoDinamico(num, 3*AREA_DE_MEMORIA[pos+1]);
        else
            agregarNodoDinamico(num, pos+1);
    } else if (num > AREA_DE_MEMORIA[pos]) {
        if (AREA_DE_MEMORIA[pos+2] != VACIO)
            agregarNodoDinamico(num, 3*AREA_DE_MEMORIA[pos+2]);
        else    
            agregarNodoDinamico(num, pos+2);
    } else     
        outputPuertoLog(CODIGO_NODO_EXISTENTE);
}


short calcularAlturaDinamico(short pos){ //imprime el ABb, 1 mayor a menor, 0 menor a mayor (3)
    if (pos != VACIO && AREA_DE_MEMORIA[pos] != VACIO && pos <= 2048/3 ){
        short altIzquierda = calcularAlturaDinamico(3*AREA_DE_MEMORIA[pos+1]) + 1;
        short altDerecha = calcularAlturaDinamico(3*AREA_DE_MEMORIA[pos+2]) + 1;
        if (altDerecha > altIzquierda)
            return altDerecha;
        else
            return altIzquierda;
    }else
        return 0;
}

short calcularSumaDinamico(short pos){ //Calcular suma (4)
    short suma = 0;
    if (pos != VACIO && pos <= 2048 && AREA_DE_MEMORIA[pos] != VACIO){
        suma = AREA_DE_MEMORIA[pos] + calcularSumaDinamico(3*AREA_DE_MEMORIA[pos+1]) + calcularSumaDinamico(3*AREA_DE_MEMORIA[pos+2]);
    }
    return suma;
}

void imprimirArbolDinamico(short pos, short orden){ //imprime el ABb, 1 mayor a menor, 0 menor a mayor (5)
    if (pos != VACIO && pos <= 2048 && AREA_DE_MEMORIA[pos] != VACIO){
        if (orden == 1 ){
            imprimirArbolDinamico(3*AREA_DE_MEMORIA[pos+2],orden);
            outputPuertoSalida(AREA_DE_MEMORIA[pos]);      
            imprimirArbolDinamico(3*AREA_DE_MEMORIA[pos+1],orden);
        }
        else if(orden == 0){
            imprimirArbolDinamico(3*AREA_DE_MEMORIA[pos+1],orden);
            outputPuertoSalida(AREA_DE_MEMORIA[pos]);      
            imprimirArbolDinamico(3*AREA_DE_MEMORIA[pos+2],orden);
        }
    }
}

//END Modo dinámico
 

void outputPuertoLog(const short codigo ){//Simula la salida puertoLog/bitácora
    printf("Puerto: %hd:%hd\n", PUERTO_LOG, codigo);
}

void outputPuertoSalida(const short codigo ){//Simula la salida puertoSalida
    printf("Puerto: %hd: %hd\n", PUERTO_SALIDA, codigo);
}

int main() {
    system("clear");
    inicializar_memoria();

    while (continuarPrograma) {
        outputPuertoLog(64);
        printf("Puerto: %hd:", PUERTO_ENTRADA);
        scanf("%hhu", &eleccion);

        switch (eleccion) {
            case 1: {
                outputPuertoLog(1);
                nodoDinamico = 0;
                inicializar_memoria();
                short num;
                printf("Puerto: %hd:", PUERTO_ENTRADA);
                scanf("%hd", &num);//debe tomar la entrada de PS actual, lo simula con scanf
                outputPuertoLog(num);
                if (num != 0 && num != 1){
                    outputPuertoLog(CODIGO_PARAMETRO_INVALIDO);
                    break;
                }
                modo = num;
                outputPuertoLog(CODIGO_EXITO);
                break;
            }
            case 2: {
                outputPuertoLog(2);
                short num;
                printf("Puerto: %hd:", PUERTO_ENTRADA);
                scanf("%hd", &num);//debe tomar la entrada de PS actual, lo simula con scanf
                outputPuertoLog(num);
                if (num > 0xFFFF){
                    outputPuertoLog(CODIGO_PARAMETRO_INVALIDO);
                }
                if (modo == 0)
                    agregarNodo(num, 0);
                else
                    agregarNodoDinamico(num, 0);
                break;
            }
            case 3: {
                outputPuertoLog(3);
                if (modo == 0)
                   outputPuertoSalida(calcularAltura(0));
                else
                   outputPuertoSalida(calcularAlturaDinamico(0));
                outputPuertoLog(CODIGO_EXITO);   
                break;
            }
            case 4: {
                outputPuertoLog(4);
                if (modo == 0)
                    outputPuertoSalida(calcularSuma(0));
                else
                    outputPuertoSalida(calcularSumaDinamico(0));
                outputPuertoLog(CODIGO_EXITO);    
                break;
            }
            case 5: {
                outputPuertoLog(5);
                short orden = 0;
                printf("Puerto: %hd:", PUERTO_ENTRADA);
                scanf("%hd", &orden);//debe tomar la entrada de PS actual, lo simula con scanf
                outputPuertoLog(orden);
                if (orden != 0 && orden != 1){
                    outputPuertoLog(CODIGO_PARAMETRO_INVALIDO);
                    break;
                }

                if (modo == 0)
                    imprimirArbol(0,orden);
                else
                    imprimirArbolDinamico(0,orden);
                outputPuertoLog(CODIGO_EXITO);
                break;
            }
            case 6: {
                outputPuertoLog(6);
                short N = 0;
                printf("Puerto: %hd:", PUERTO_ENTRADA);
                scanf("%hd", &N);//debe tomar la entrada de PS actual, lo simula con scanf
                if (modo == 0){
                    if (N > 2048){
                        outputPuertoLog(CODIGO_PARAMETRO_INVALIDO);
                        break;
                    }
                    imprimirMemoria(N);
                }else{
                    if (N > 2048/3){
                    outputPuertoLog(CODIGO_PARAMETRO_INVALIDO);
                    }
                    N=3*N;
                    imprimirMemoria(N);
                }
                outputPuertoLog(CODIGO_EXITO);    
                break;
            }
            case 255: {
                outputPuertoLog(255);
                continuarPrograma = 0;
                break;
            }                        

            default: {
                outputPuertoLog(CODIGO_COMANDO_INVALIDO);
                break;
            }
        }
    }

    return 0;
}
