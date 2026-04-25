# CS224: Extended RV32IM Processor with Mathematical Acceleration Unit (MAU)

## 📌 Overview
This project implements an extended **3-stage pipelined RV32IM RISC-V processor** enhanced with a **Custom Mathematical Acceleration Unit (MAU)** on a Xilinx Artix-7 FPGA (Nexys A7). 

By expanding the base RV32I ISA from ~40 instructions to 53, the processor natively supports hardware multiplication/division and custom DSP instructions (ABS, MAX, MIN, SQRT, LOG2), eliminating expensive software emulation loops for mathematical workloads.

**Course:** CS 224 – Hardware Lab  
**Group Number:** 19

---

## 🏗️ System Architecture

### 3-Stage Pipeline
Unlike standard 5-stage RISC-V implementations, this processor utilizes a compact **3-stage pipeline** (`IF/ID` → `EX` → `MEM/WB`):
1. **IF/ID (Instruction Fetch & Decode):** Fetches instructions from BRAM, decodes opcodes (including RV32M and Custom-0), reads register files, and handles pipeline stalling.
2. **EX (Execute):** The core compute stage. Contains the standard ALU and routes operands to the Multiplier, Divider, and MAU. Includes a large result multiplexer.
3. **MEM/WB (Memory & Writeback):** Handles Data Memory load/store operations and writes computed results back to the Register File.

### Multi-Cycle Stall Logic
Since multi-cycle operations (MUL: 3c, DIV: 32c, SQRT: 16c) reside in the `EX` stage, a unified stall controller freezes the PC and `IF/ID` pipeline registers until the specific unit asserts its `done` signal. Single-cycle operations (ABS, MAX, MIN, LOG2) pass through without stalls.

---

## 🧮 Instruction Set Architecture (ISA)

### 1. RV32M Extension (Hardware Multiply/Divide)
*   **MUL, MULH, MULHU, MULHSU:** 32x32 multiplication returning 64-bit results (truncated to lower/upper 32 bits depending on instruction).
*   **DIV, DIVU, REM, REMU:** 32-bit hardware division and remainder. Fully compliant with RISC-V edge cases (`INT_MIN / -1` overflow, Divide-by-Zero).

### 2. Custom MAU (Opcode: `0001011`)
Uses the standard RISC-V `custom-0` opcode space mapped via `funct3`.
*   `ABS`: Absolute value (1-cycle combinational)
*   `MAX`: Maximum of two registers (1-cycle combinational)
*   `MIN`: Minimum of two registers (1-cycle combinational)
*   `SQRT`: 32-bit integer square root (16-cycle FSM)
*   `LOG2`: Log base 2 via Count Leading Zeros (1-cycle O(1) tree)

---

## ⚙️ Hardware Modules

| Module | File | Description |
| :--- | :--- | :--- |
| **Multiplier** | `multiplier.v` | 3-cycle pipelined 32x32 multiplier mapped to Xilinx DSP48 slices. |
| **Divider** | `divider.v` | 32-cycle restoring algorithm FSM with pre-check for RISC-V edge cases. |
| **MAU Simple** | `mau_simple.v` | Combinational logic for ABS, MAX, MIN. |
| **SQRT Unit** | `sqrt_unit.v` | 16-cycle non-restoring FSM (processes 2 bits/cycle). |
| **CLZ Unit** | `clz_unit.v` | 5-level hierarchical LUT priority encoder for O(1) LOG2. |
| **Execute Stage**| `execute.v` | Extended datapath with result MUX for ALU/MUL/DIV/MAU. |
| **Control** | `opcode.vh` | Decodes RV32IM `funct7` and Custom-0 opcodes. |
| **Peripherals** | `sev_seg.v` | Drivers for  7-segment displays. |

---

## 🚀 Use Cases & FPGA Validation
The system was validated on the FPGA using 5+ C programs compiled with `-march=rv32im`:
1. **DSP Filtering:** 16-tap FIR filter using `MUL` and `ABS`.
2. **Euclidean Distance:** Calculates $\sqrt{(x_1-x_2)^2 + (y_1-y_2)^2}$ using `SUB`, `MUL`, `ADD`, `SQRT`.
3. **Data Normalization:** Clamping sensor data using `MAX`/`MIN`.
4. **Logarithmic Scaling:** Decibel conversion using `LOG2`.
5. **GCD Calculation:** Recursive division using `DIV`/`REM`.

---

## 📊 Resource Utilization (Synthesis Estimates)
*Target: Xilinx Artix-7 XC7A100T (Nexys A7)*

| Resource | Usage | Utilization |
| :--- | :--- | :--- |
| LUTs | ~4,125 | ~6.5% |
| Flip-Flops | ~2,540 | ~2.0% |
| BRAM (36Kb) | 4 | ~3.0% |
| DSP Slices | 3 | ~1.2% |

---

## 🛠️ Setup & Getting Started

### Prerequisites
*   Xilinx Vivado (2022.1 or later recommended)
*   RISC-V GNU Toolchain (`riscv32-unknown-elf-gcc`)

### Compiling C Programs for the Processor
Use the provided Makefile or run the following command to compile a C program into instruction memory hex files:
```bash
riscv32-unknown-elf-gcc -O1 -march=rv32im -mabi=ilp32 -nostdlib -T linker.ld -o program.elf program.c
riscv32-unknown-elf-objcopy -O verilog program.elf program.hex
```
  ###OR Another Way to generate Hex Files
Add everything required to generate mem files to makefile
```bash
make <your_c_prog_name>
```
### Simulation
Module-level testbenches (e.g., `tb_multiplier.v`, `tb_divider.v`) can be run using Vivado XSIM or ModelSim. Golden vectors are generated via the included Python scripts:
```bash
python3 gen_vectors.py > test_vectors.txt
```

### FPGA Build
1. Open Vivado and create a project targeting the `xc7a100tcsg324-1` FPGA.
2. Add all `.v` and `.vh` files from the `src/` directory.
3. Set `top_module.v` as the top module.
4. Add the provided `Nexys-A7-100T.xdc` constraints file.
5. Run Synthesis, Implementation, and Generate Bitstream.

---

## 👥 Team Members

| Name | Roll Number | Responsibilities |
| :--- | :--- | :--- |
| **Komirisetty Prabhas** | 240101045 | Multiplier (DSP48), CLZ/LOG2, Pipeline EX modifications, Synthesis |
| **Karyampudi Komal** | 240101041 | Divider (Restoring FSM), Pipeline Stall Logic, Python Golden Vectors, C Programs |
| **Kasireddi Sai Chandra Kiran Naidu** | 240101042 | MAU Simple (ABS/MAX/MIN), SQRT FSM, UART/Display Drivers, FPGA Integration |
