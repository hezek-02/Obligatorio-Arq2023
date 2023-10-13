#include <stdio.h>
#include <stdlib.h>

/**
 * @file MOAB.c
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

typedef struct{
    short num;
    short izq;
    short der;
} nodo;

short vacio = 0x8000;
short tope = 2048;
short AREA_DE_MEMORIA[2048];
const short PUERTO_ENTRADA = 20;
const short PUERTO_SALIDA = 21;
const short PUERTO_LOG = 22;

char eleccion = NULL;
char continuarPrograma = 1;

void inicializar_memoria(){
    for (short i = 0; i < tope; i++){
        AREA_DE_MEMORIA[i] = vacio;
    }
}


int main() {
    system("clear");

    while (continuarPrograma) {
        printMenu();
        scanf("%d", &eleccion);

        switch (eleccion) {
            case 1: {
                system("clear");
                break;
            }
            case 2: {
                system("clear");
                break;
            }
            case 3: {
                system("clear");
                break;
            }
            case 4: {
                system("clear");
                break;
            }
            case 5: {
                system("clear");
                break;
            }
            case 6: {
                system("clear");
                break;
            }
            case 255: {
                system("clear");
                break;
            }                        

            case 0: {
                continuarPrograma = 0;
                break;
            }
            default: {
                break;
            }
        }
    }

    return 0;
}