#include <stdio.h>
#include "custom_assembler.h"

int main()
{
  int a=21;
  int b=19;
  int c=a^b;
  mmio_write(ADDR_SEVSEG, c); 
  return 0;
}
