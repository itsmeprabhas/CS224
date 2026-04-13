import random
import math

# Funct3 mappings for the MAU instructions
OPS = {
    "ABS":  "000",
    "MAX":  "001",
    "MIN":  "010",
    "LOG2": "100"
}

def to_hex(val):
    """Formats a number as a 32-bit uppercase Hex string (8 characters)"""
    return f"{val & 0xFFFFFFFF:08X}"

def generate_mau_standalone_vectors(filename="input.txt", num_random=50):
    with open(filename, 'w') as f:
        
        def write_case(op_name, a, b):
            funct3 = OPS[op_name]
            
            # --- Calculate Golden Output ---
            if op_name == "ABS":
                golden = abs(a) & 0xFFFFFFFF
            elif op_name == "MAX":
                golden = max(a, b) & 0xFFFFFFFF
            elif op_name == "MIN":
                golden = min(a, b) & 0xFFFFFFFF
            elif op_name == "LOG2":
                u_a = a & 0xFFFFFFFF
                if u_a == 0:
                    golden = 0 
                else:
                    golden = int(math.log2(u_a))
            
            # Format: Funct3(3-bin) OpA(8-hex) OpB(8-hex) Expected(8-hex)
            f.write(f"{funct3} {to_hex(a)} {to_hex(b)} {to_hex(golden)}\n")

        # ---------------------------------------------------------
        # 1. HARDCODED EDGE CASES (Matching your exact examples)
        # ---------------------------------------------------------
        write_case("ABS", -1, 0)
        write_case("ABS", -2147483648, 0)
        write_case("MAX", 5, 10)
        write_case("MAX", -5, 3)
        write_case("MAX", -2147483648, 2147483647)
        write_case("MIN", 5, 10)
        write_case("MIN", -5, 3)
        write_case("MIN", -2147483648, 2147483647)
        write_case("LOG2", 0, 0)
        write_case("LOG2", 8, 0)
        write_case("LOG2", 256, 0)
        write_case("LOG2", -2147483648, 0)

        # ---------------------------------------------------------
        # 2. RANDOMIZED STRESS TEST
        # ---------------------------------------------------------
        for _ in range(num_random):
            a = random.randint(-2147483648, 2147483647)
            b = random.randint(-2147483648, 2147483647)
            op = random.choice(list(OPS.keys()))
            write_case(op, a, b)

if __name__ == "__main__":
    generate_mau_standalone_vectors()
