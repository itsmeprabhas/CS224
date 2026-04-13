import random

# Opcodes mapped to our divider testbench format
# Format: "Operation": (div_op_encoded)
# 00 = DIV (Signed Division)
# 01 = DIVU (Unsigned Division)
# 10 = REM (Signed Remainder)
# 11 = REMU (Unsigned Remainder)
OPS = {
    "DIV":  0,
    "DIVU": 1,
    "REM":  2,
    "REMU": 3
}

def to_hex(val):
    """Masks a Python integer to 32-bit two's complement and formats as uppercase Hex."""
    return f"{val & 0xFFFFFFFF:08X}"

def generate_vectors(filename, num_random=20):
    with open(filename, 'w') as f:
        
        def write_case(op_name, a, b):
            div_op = OPS[op_name]
            
            # Convert inputs to 32-bit unsigned equivalents for Unsigned math
            u_a = a & 0xFFFFFFFF
            u_b = b & 0xFFFFFFFF

            # --- Calculate Golden Output in Python based on RISC-V Specs ---
            if op_name == "DIV":
                if b == 0:
                    golden = -1 # All 1's (0xFFFFFFFF)
                elif a == -2147483648 and b == -1:
                    golden = -2147483648 # Overflow limit
                else:
                    # Python's normal '//' rounds to negative infinity. 
                    # int(a/b) strictly truncates towards zero matching C/Verilog.
                    golden = int(a / b)
                    
            elif op_name == "DIVU":
                if u_b == 0:
                    golden = -1 # 0xFFFFFFFF
                else:
                    golden = u_a // u_b
                    
            elif op_name == "REM":
                if b == 0:
                    golden = a
                elif a == -2147483648 and b == -1:
                    golden = 0
                else:
                    # Python's '%' takes sign of divisor. We must emulate taking sign of dividend!
                    # Formula: A - (A/B_truncated) * B
                    quotient = int(a / b)
                    golden = a - (quotient * b)
                    
            elif op_name == "REMU":
                if u_b == 0:
                    golden = u_a
                else:
                    golden = u_a % u_b
            
            # --- Write line formatted for Verilog $fscanf ---
            # Format: OpA OpB OpCode Expected Output
            f.write(f"{to_hex(a)} {to_hex(b)} {div_op} {to_hex(golden)}\n")

        print(f"Generating Golden Test Vectors into {filename}...")

        # ---------------------------------------------------------
        # 1. HARDCODED EDGE CASES (To guarantee corners pass)
        # ---------------------------------------------------------
        # Division by zero
        write_case("DIV", 10, 0)
        write_case("REM", 10, 0)
        write_case("DIVU", 10, 0)
        write_case("REMU", 10, 0)
        write_case("DIV", -10, 0) # Negative / 0
        write_case("REM", -10, 0) # Negative % 0
        write_case("DIV", 0, 0)   # 0 / 0
        write_case("REM", 0, 0)   # 0 % 0
        
        # RISC-V Signed Overflow edge cases
        write_case("DIV", -2147483648, -1) 
        write_case("REM", -2147483648, -1)
        
        # Basic mixed-sign tests
        write_case("DIV", -35, -16) 
        write_case("REM", -35, -16)
        write_case("DIV", 20, -4) 
        write_case("REM", 20, -3) 

        # ---------------------------------------------------------
        # 2. RANDOMIZED STRESS TEST
        # ---------------------------------------------------------
        # Generates a massive batch of random numbers to stress the hardware
        for _ in range(num_random):
            a = random.randint(-2147483648, 2147483647)
            b = random.randint(-2147483648, 2147483647)
            op = random.choice(list(OPS.keys()))
            write_case(op, a, b)

if __name__ == "__main__":
    # You can change 'num_random' to 1000 to really stress-test your processor!
    generate_vectors("input.txt", num_random=200)
    print("Success! You can now use this input.txt in Vivado.")
