#include <stdio.h>


char decimalToBCD(char decimal) {
    char high = decimal / 10;  // Dígito de las decenas
    char low = decimal % 10;   // Dígito de las unidades

    return (high << 4) | low;
}

// Escribir un algoritmo que permita sumar dos enteros de hasta 2 dígitos,
// representados como enteros sin signo empaquetado (BCD). El resultado se
// expresa también en BCD.

//nnnn nnnn, xxxx xxxx
short sumaBCD(char num1, char num2){
    char num1Uni = num1 & 0x0F;
    char num2Uni = num2 & 0x0F;
    char carry = 0;

    char sumUnidades = num1Uni + num2Uni;
    printf("%hhx\n",num1Uni);
    printf("%hhx\n",num2Uni);
    printf("%hhx\n",sumUnidades);
    if (sumUnidades>0x09){
        sumUnidades -= 0x0A;
        carry = 1;
    }
    printf("%hhx\n",sumUnidades);
    char num1Dec = num1 >> 4;
    char num2Dec = num2 >> 4;
    char sumDecenas = num1Dec + num2Dec;
    
 
    if (carry==1){
        sumDecenas+= 0x01;
    }
    if (sumDecenas>0x09){
        sumDecenas -= 0x0A;
        carry = 1;
        return -1;
    }
    printf("%hhx\n",sumDecenas);
    sumDecenas = sumDecenas << 4;
    return sumUnidades+sumDecenas;

}

int main(){
    char n1, n2;

    //Directo como hexadecimales
    printf("Ingrese el primer número (0-99)formato BCD: ");
    scanf("%hhx", &n1);

    printf("Ingrese el segundo número (0-99)formato BCD: ");
    scanf("%hhx", &n2);

    printf("\t%02hhX \n",sumaBCD(n1, n2));

    //Conversion a Hex, entrada decimal
    printf("Ingrese el primer número (0-99)formato BCD: ");
    scanf("%hhd", &n1);

    printf("Ingrese el segundo número (0-99)formato BCD: ");
    scanf("%hhd", &n2);

    n1 = decimalToBCD(n1);
    n2 = decimalToBCD(n2);

    printf("\t%02hhX\n",sumaBCD(n1, n2));
    return 0;
}

