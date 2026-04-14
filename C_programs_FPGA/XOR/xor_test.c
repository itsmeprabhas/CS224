#include <stdint.h>

#define SEV_SEG_ADDR 0x00002000
volatile uint32_t* const SEV_SEG_PTR = (uint32_t*)SEV_SEG_ADDR;

int main() {
    uint32_t a = 0x0000ABCD;
    uint32_t b = 0x00001234;
    *SEV_SEG_PTR = a ^ b;
    while(1) {}
    return 0;
}
