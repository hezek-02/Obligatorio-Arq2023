#include <stdio.h>
#include <math.h>
// Escriba programas que realicen las siguientes conversiones de enteros de
// 16 bits:
// a) De complemento a 1 a magnitud y signo
// b) De complemento a 2 a desplazamiento, con D = 128=2⁷

//b
//asume q num esta en complemento a 2
void complemento_a_2_a_desplazamiento(short num) {
    unsigned short magnitud;
    short desplazamiento;
    short D = 128;
    char signo = 1;
    if (num < -128 || num > (pow(2, 15) -1 -pow(2, 7)) )
        printf("OVERFLOW");
    if (num & (1 << 15)) {//es negativo
        magnitud = (~num + 1);
        signo = -1;
    } else {
        magnitud = num;
    }

    desplazamiento = (signo*magnitud) + D;
    
    printf("%d * Magnitud:%d\n", signo, magnitud);
    printf("Valor:%d\n", desplazamiento);
    printf("Desp:%d\n", D);
    printf("ValorHexDesp:%hx\n", desplazamiento);

}

//a
//asume q num esta en complemento a 1
void complemento_a_1_a_magnitud_signo(short num) {
    char signo ='+';
    unsigned short magnitud;

    if (num & (1 << 15)) {//si el bit sign es uno
        signo = '-';
        magnitud = (~num);
    } else {
        signo = '+';
        magnitud = num;
    }
    //formato puro
    printf("Signo: %c, Magnitud: %d\n", signo, magnitud);
    printf("Signo: %c, Magnitud: %hx\n", signo, magnitud);
}


int main() {
    short num;

    printf("Ingresa un número: ");
    scanf("%hd", &num);
    //de compl2 a 1
    if (num < 0)
        num = (num - 0x0001);
    complemento_a_1_a_magnitud_signo(num);

    printf("Ingresa un número: ");
    scanf("%hd", &num);
    complemento_a_2_a_desplazamiento(num);

    return 0;
}