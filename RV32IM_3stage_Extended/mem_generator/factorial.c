#include <stdio.h>
#include "custom_assembler.h"

int main(){
	int n=5;
	int result=1;
	for(int i=2;i<=n;++i) result=hw_mul(result,i);
	mmio_write(ADDR_SEVSEG, result); 
	return 0;
}
