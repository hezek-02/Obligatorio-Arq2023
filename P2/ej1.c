#include <stdio.h>


int main(){
    //a
    short a1 = 0xA87B;
    short b1 = 0x771C;
    short c = a1 | b1;
    short x = c >> 4;
    char d = x ;


    printf("%02hX = %d\n",a1,a1);
    printf("%02hX = %d\n",b1,b1);
    printf("%02hX = %d\n",c,c);
    printf("%02hhX = %d\n", d, d);

    //b
    char a2 = 7;
    char b2 = 0xF3;
    char c2 = 5;
    short d2 = a2 << 12 | b2 << 4 | c2;

    printf("%02hhX = %d\n", a2, a2);
    printf("%02hhX = %d\n", b2, b2);
    printf("%02hX = %d\n", a2<<12, a2);

    printf("%02hhX = %d\n", c2, c2);
    printf("%02hX = %d\n", d2, d2);

    //c
    char a = -3;
    char b = 0x80;
    short res = a + b;

    printf("%02hX = %d\n", a2<<12, a2);
    printf("%02hhX = %d\n", c2, c2);
    printf("%02hX = %d\n", d2, d2);
    
    return 0;
}