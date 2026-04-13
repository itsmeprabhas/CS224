import random

# Funct3 mappings for the 4 RV32M multiplier instructions
OPS =  {
    "MUL":    "000", # Signed * Signed
    "MULH":   "001", # Signed * Signed
    "MULHSU": "010", # Signed * Unsigned
    "MULHU":  "011"  # Unsigned * Unsigned
}

def to_hex32(val):
    """Formats a number as a 32-bit uppercase Hex string (8 characters)"""
    return f"{val & 0xFFFFFFFF:08X}"

def to_hex64(val):
    """Formats a number as a 64-bit uppercase Hex string (16 characters)"""
    return f"{val & 0xFFFFFFFFFFFFFFFF:16X}"

def generate_mul_standalone_vectors(filename="input.txt", num_random=50):
    with open(filename, 'w') as f:
        
        def write_case(op_name, a, b):
            funct3 = OPS[op_name]
            
            # Convert inputs to Python-native unsigned values for specific operations
            u_a = a & 0xFFFFFFFF
            u_b = b & 0xFFFFFFFF
            
            # --- Calculate Full 64-bit Product ---
            # In the standalone hardware multiplier, it ALWAYS outputs 64 bits.
            # The execution pipeline is what chops it to 32 bits later.
            if op_name in ["MUL", "MULH"]:
                # Signed * Signed
                golden_64 = a * b
            elif op_name == "MULHSU":
                # Signed * Unsigned
                golden_64 = a * u_b
            elif op_name == "MULHU":
                # Unsigned * Unsigned
                golden_64 = u_a * u_b
            
            # Format: OpA(8-hex) OpB(8-hex) Funct3(3-bin) Expected(16-hex)
            f.write(f"{to_hex32(a)} {to_hex32(b)} {funct3} {to_hex64(golden_64)}\n")

        print(f"Generating 64-bit Multiplier Test Vectors into {filename}...")

        # ---------------------------------------------------------
        # 1. HARDCODED EDGE CASES (Matching your exact examples)
        # ---------------------------------------------------------
        write_case("MUL", 0, 0)
        write_case("MUL", 1, 1)
        write_case("MUL", -1, -1)
        write_case("MULH", -1, 1)
        write_case("MULH", -2147483648, 1) # INT_MIN * 1
        write_case("MULHU", -1, -1)        # MAX_UNSIGNED * MAX_UNSIGNED
        write_case("MULHSU", -1, 1)        # -1 * 1 (Unsigned)
        
        # ---------------------------------------------------------
        # 2. RANDOMIZED STRESS TEST
        # ---------------------------------------------------------
        for _ in range(num_random):
            a = random.randint(-2147483648, 2147483647)
            b = random.randint(-2147483648, 2147483647)
            op = random.choice(list(OPS.keys()))
            write_case(op, a, b)

if __name__ == "__main__":
    # Generates your file with 50 random stress tests
    generate_mul_standalone_vectors()
    print("Success! input.txt is ready for your standalone multiplier testbench.")
