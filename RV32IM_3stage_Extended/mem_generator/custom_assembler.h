#include <stdint.h>
volatile int32_t result;
/* 
 * 1. Core Instruction Constructor (R-Type)
 * Standard Layout: [funct7(7) | rs2(5) | rs1(5) | funct3(3) | rd(5) | opcode(7)]
 */
#define R_TYPE_VAL(f7, rs2, rs1, f3, rd, op) \
    ((((uint32_t)(f7)) << 25) | (((uint32_t)(rs2)) << 20) | (((uint32_t)(rs1)) << 15) | \
     (((uint32_t)(f3)) << 12) | (((uint32_t)(rd)) << 7) | ((uint32_t)(op)))

/* 
 * 2. Hardware Constants (Verified from opcode.vh & IF_ID.v)
 */
#define RV32M_OP    0x33  // ARITHR (Standard OP)
#define CUSTOM_OP   0x0B  // CUSTOM_0 (Your MAU Extension)
#define F7_EXT      0x01  // Required for both RV32M and Custom MAU in your IF_ID.v

/* 
 * 3. Funct3 Mappings (Verified from mau_simple.v & IF_ID.v)
 */
#define F3_MUL      0x0
#define F3_DIV      0x4
#define F3_REM      0x6
#define F3_ABS      0x0
#define F3_MAX      0x1
#define F3_MIN      0x2
#define F3_SQRT     0x3
#define F3_LOG2     0x4

/* 
 * 4. Inline Execution Wrappers
 * We use a0 (x10) and a1 (x11) for high compatibility with standard calling conventions.
 */

#define ASM_HW_2OP(rs1, rs2, f3, op) ({ \
    uint32_t res; \
    asm volatile ( \
        "mv a0, %1\n\t" \
        "mv a1, %2\n\t" \
        ".word %3\n\t" \
        "mv %0, a0" \
        : "=r" (res) \
        : "r" (rs1), "r" (rs2), "i" (R_TYPE_VAL(F7_EXT, 11, 10, f3, 10, op)) \
        : "a0", "a1" \
    ); \
    res; \
})

#define ASM_HW_1OP(rs1, f3, op) ({ \
    uint32_t res; \
    asm volatile ( \
        "mv a0, %1\n\t" \
        ".word %2\n\t" \
        "mv %0, a0" \
        : "=r" (res) \
        : "r" (rs1), "i" (R_TYPE_VAL(F7_EXT, 0, 10, f3, 10, op)) \
        : "a0" \
    ); \
    res; \
})

// RV32M Wrappers
static inline int32_t  hw_mul(int32_t a, int32_t b)   { return (int32_t)ASM_HW_2OP(a, b, F3_MUL, RV32M_OP); }
static inline int32_t  hw_div(int32_t a, int32_t b)   { return (int32_t)ASM_HW_2OP(a, b, F3_DIV, RV32M_OP); }
static inline int32_t  hw_rem(int32_t a, int32_t b)   { return (int32_t)ASM_HW_2OP(a, b, F3_REM, RV32M_OP); }
// Custom MAU Wrappers
static inline int32_t  hw_abs(int32_t a)              { return (int32_t)ASM_HW_1OP(a, F3_ABS, CUSTOM_OP); }
static inline int32_t  hw_max(int32_t a, int32_t b)   { return (int32_t)ASM_HW_2OP(a, b, F3_MAX, CUSTOM_OP); }
static inline int32_t  hw_min(int32_t a, int32_t b)   { return (int32_t)ASM_HW_2OP(a, b, F3_MIN, CUSTOM_OP); }
static inline uint32_t hw_sqrt(uint32_t a)            { return ASM_HW_1OP(a, F3_SQRT, CUSTOM_OP); }
static inline uint32_t hw_log2(uint32_t a)            { return ASM_HW_1OP(a, F3_LOG2, CUSTOM_OP); }

// MMIO Addresses (from top_fpga.v)
#define ADDR_LED      0x40000000
#define ADDR_SW       0x40000004
#define ADDR_SEVSEG   0x4000000C

static inline void mmio_write(uint32_t addr, uint32_t data) {
    *(volatile uint32_t*)addr = data;
}
