#include <stdio.h>
#include "custom_assembler.h"

int main() {
    // 1. Euclidean Distance Calculation: sqrt((x1-x2)^2 + (y1-y2)^2)
    int x1 = 16;
    int y1 = 0;
    int x2 = 0;
    int y2 = 7;
    
    int dx = x1 - x2;        
    int dy = y1 - y2;        
    
    // Using hardware multiplier for squaring
    int prodx = hw_mul(dx, dx); 
    int prody = hw_mul(dy, dy); 
    
    int sumofsq = prodx + prody; 
    
    // Using hardware sqrt unit
    int distance = hw_sqrt(sumofsq);

    // 2. Output to 7-Segment Display
    mmio_write(ADDR_SEVSEG, distance); 

    return 0;
}
