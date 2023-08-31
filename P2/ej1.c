#include <stdio.h>


int main(){
    //a
    short a1 = 0xA87B;
    short b2 = 0x771C;
    short c = a1 | b2;
    short x = c >> 4;
    char d = x ;


    printf("%02hX = %d\n",a1,a1);
    printf("%02hX = %d\n",b2,b2);
    printf("%02hX = %d\n",c,c);

    printf("%02hhX = %d\n", d, d);
    //b
   
    return 0;
}