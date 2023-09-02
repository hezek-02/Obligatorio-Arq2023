#include <stdio.h>

int extraerBits(int palabra, int bitAlto, int bitBajo) {
    // Asegurarse de que bitAlto >= bitBajo
    if (bitAlto < bitBajo) {
        int temp = bitAlto;
        bitAlto = bitBajo;
        bitBajo = temp;
    }

    // Crear una máscara para extraer los bits deseados
    int mascara = ((1 << (bitAlto - bitBajo + 1)) - 1) << bitBajo;//tomo 2^bitalto-1

    // Aplicar la máscara a la palabra para extraer los bits
    int resultado = (palabra & mascara) >> bitBajo;

    return resultado;
}

int main() {
    int palabra = 0b10101010101010000000111001101;
    int bitBajo = 2;
    int bitAlto = 6;

    int resultado = extraerBits(palabra, bitAlto, bitBajo);

    printf("Los bits %d..%d de la palabra son: %hx\n", bitAlto, bitBajo, resultado);

    return 0;
}
