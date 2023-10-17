#include <stdio.h>
#include <stdlib.h>

/**
 *
 * El programa permite interactuar con un árbol mediante comandos de la siguiente forma:
 *
 * - Cambiar Modo (Comando: 1, Parámetro: Modo)
 *   Cambia el modo de almacenamiento del árbol e inicializa el área de memoria.
 *
 * - Agregar Nodo (Comando: 2, Parámetro: Número)
 *   Agrega el número al árbol.
 *
 * - Calcular Altura (Comando: 3)
 *   Imprime la altura del árbol.
 *
 * - Calcular Suma (Comando: 4)
 *   Imprime la suma de todos los números del árbol.
 *
 * - Imprimir Árbol Orden (Comando: 5, Parámetro: 0-1)
 *   Imprime todos los números del árbol. El parámetro orden indica si se imprimen
 *   de menor a mayor (0) o de mayor a menor (1).
 *
 * - Imprimir Memoria N (Comando: 6, Parámetro: N)
 *   Imprime los primeros N nodos del área de memoria del árbol.
 *
 * - Detener programa (Comando: 255)
 *   Detiene la ejecución del programa.
 *
 */

//para metodo dinamico
typedef struct{
    short num;
    short izq;
    short der;
} nodo;

short AREA_DE_MEMORIA[2048];
const short VACIO = 0x8000;
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


unsigned char eleccion ;
char continuarPrograma = 1;

void inicializar_memoria(){
    for (short i = 0; i < 2048; i++){
        AREA_DE_MEMORIA[i] = VACIO;
    }
}

void agregarNodo(short num, short nodo){ //insertarEnABB
    if (nodo>=2048){
        outputPuertoLog(CODIGO_ESCRITURA_INVALIDA);
        return;
    }
    if (AREA_DE_MEMORIA[nodo] == VACIO){
        AREA_DE_MEMORIA[nodo] = num;
        outputPuertoLog(CODIGO_EXITO);
    }else{
        if(AREA_DE_MEMORIA[nodo]>num)
            agregarNodo(num, nodo+2);
        else if(AREA_DE_MEMORIA[nodo]<num)
            agregarNodo(num, nodo+1);
        else
            outputPuertoLog(CODIGO_NODO_EXISTENTE);
    }
}

void imprimirArbol(short nodo, char orden){ //imprime el ABb, 1 mayor a menor, 0 menor a mayor
    if (nodo < 2048 && AREA_DE_MEMORIA[nodo] != VACIO){
        if (orden == 1 ){
            imprimirArbol(nodo+2,orden);
            outputPuertoSalida(AREA_DE_MEMORIA[nodo]);      
            imprimirArbol(nodo+1,orden);
        }
        else if(orden == 0){
            imprimirArbol(nodo+1,orden);
            outputPuertoSalida(AREA_DE_MEMORIA[nodo]);      
            imprimirArbol(nodo+2,orden);
        }
    }
}

void outputPuertoLog(const short codigo ){//Simula la salida puertoLog/bitácora
    printf("%hd:%hd\n", PUERTO_LOG, codigo);
}

void outputPuertoSalida(const short codigo ){//Simula la salida puertoSalida
    printf("Puerto: %hd, %hd\n", PUERTO_SALIDA, codigo);
}

int main() {
    system("clear");
    inicializar_memoria();

    while (continuarPrograma) {
        outputPuertoLog(64);
        scanf("%hhu", &eleccion);

        switch (eleccion) {
            case 1: {
                inicializar_memoria();
                break;
            }
            case 2: {
                short num;
                scanf("%hd", &num);//debe tomar la entrada de PS actual, lo simula con scanf
                outputPuertoLog(num);
                // if (num){
                //     outputPuertoLog(CODIGO_PARAMETRO_INVALIDO);
                // }
                
                agregarNodo(num, 0);
                break;
            }
            case 3: {
                printf("Calcular Altura");
                break;
            }
            case 4: {
                printf("Calcular Suma");
                break;
            }
            case 5: {
                short orden = 0;
                scanf("%hd", &orden);//debe tomar la entrada de PS actual, lo simula con scanf
                if(orden != 0 || orden != 1){
                    outputPuertoLog(CODIGO_PARAMETRO_INVALIDO);
                }
                outputPuertoLog(orden);
                imprimirArbol(0,orden);
                break;
            }
            case 6: {
                printf("Imprimir Memoria");
                break;
            }
            case 255: {
                printf("Detener programa");
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
