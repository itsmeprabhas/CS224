#include <stdio.h>
#include "custom_assembler.h"

int main(){
	int x=18;
	int y=24;
	int a=hw_max(x,y);
	int b=hw_min(x,y);
	while (b != 0) {
        	int temp = b;
        	b = hw_rem(a, b); 
        	a = temp;
   	}
	mmio_write(ADDR_SEVSEG, a); 
	return 0;
}
