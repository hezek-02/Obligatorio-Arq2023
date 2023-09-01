#include <stdio.h>


char decimalToBCD(char decimal) {
    char high = decimal / 10;  // Dígito de las decenas
    char low = decimal % 10;   // Dígito de las unidades

    return (high << 4) | low;
}

// Escribir un algoritmo que permita sumar dos enteros de hasta 2 dígitos,
// representados como enteros sin signo empaquetado (BCD). El resultado se
// expresa también en BCD.

//nnnn nnnn, xxxx xxxx, se puede expandir dado la entrada short, int, long a mas caracteres
short sumaBCD(char num1, char num2){
    char carry = 0;
    char shift = 0;
    short suma[3];
    for (int h = 0; h < 3; h++){
        suma[h]=0;
    }
    short total = 0;
    int i = 0;

    while (i<3){
        shift = 4*i;
        suma[i] = ((num1  & 0x00FF) >> shift) + ((num2  & 0x00FF) >> shift);  //usar unsigned char o hacer conversion para q no tome complemento a 2
        suma[i] = suma[i] & 0x000F;  
        if (carry==1){
            suma[i]+= 0x0001;
        }
        if (suma[i]>0x0009){
            suma[i]-= 0x000A;
            carry = 1;
        }else{
            carry = 0;
        }
        suma[i] = suma[i] << shift;
        i++;
    }

    for (int j = 0; j < i; j++){
        total = total | suma[j];//incluso |
    }
    
    return total;
    // printf("%hhx\n",num2Uni);
    // printf("%hhx\n",sumUnidades);
}

int main(){
    char n1, n2;

    //Directo como hexadecimales
    printf("Ingrese el primer número (0-99)formato BCD: ");
    scanf("%hhx", &n1);

    printf("Ingrese el segundo número (0-99)formato BCD: ");
    scanf("%hhx", &n2);

    printf("\t%hX\n",sumaBCD(n1, n2));

    //Conversion a Hex, entrada decimal
    printf("Ingrese el primer número (0-99)formato BCD: ");
    scanf("%hhd", &n1);

    printf("Ingrese el segundo número (0-99)formato BCD: ");
    scanf("%hhd", &n2);

    n1 = decimalToBCD(n1);
    n2 = decimalToBCD(n2);

    printf("\t%hX\n",sumaBCD(n1, n2));
    return 0;
}

