#include <stdio.h>

int calcularParidad(int palabra) {
    int paridad = 0;
    
    for (int i = 0; i < 32; i++){
        paridad ^= (palabra & 1); // XOR con el último bit
        palabra >>= 1; // Desplazar a la derecha
    
    }
    

    return paridad;
}

int main() {
    int palabra;
    
    printf("Ingrese una palabra de 32 bits en hexadecimal: 0x");
    scanf("%x", &palabra);
    
    int resultado = calcularParidad(palabra);
    
    if (resultado == 0) {
        printf("La paridad es PAR.\n");
    } else {
        printf("La paridad es IMPAR.\n");
    }
    
    return 0;
}