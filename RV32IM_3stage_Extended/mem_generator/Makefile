#//////////////////////////////////////////////////////
#/////////////////INCLUDING CROSS-COMPILER/////////////

CC      = riscv-none-elf-gcc
AR      = riscv-none-elf-ar
OBJDUMP = riscv-none-elf-objdump
OBJCOPY = riscv-none-elf-objcopy
READELF = riscv-none-elf-readelf


#///// flags for RV32i architecture///////////////////
CFLAGS  = -march=rv32i -mabi=ilp32 -O2 -nostartfiles -mno-relax -fno-builtin


#////Source for c code file ///////////////////////////
SRC_ADDITION     = code_addition.c
SRC_SORT     = code_sort.c
SRC_NEGATIVE = code_negative.c
SRC_FIBONACCI = code_fibonacci.c
SRC_XOR       = code_xor.c
SRC_DISTANCE    = euclidean_distance.c
SRC_FACTORIAL = factorial.c
SRC_GCD = gcd.c

TARGET   = code.elf

.PHONY: all clean

#/// generating .text file of code cross-compiled from highlevel-c code to risc-v code
# ////////////// Copying and converting the text file into binary files
#/////// Python script to convert the binary files into the required hex files

addition: $(SRC_ADDITION)
	$(CC) $(SRC_ADDITION) -o $(TARGET) $(CFLAGS) -Ttext 0
	$(OBJCOPY) -O binary $(TARGET) ./imem_dmem/imem.bin
	$(OBJCOPY) -j .data -O binary $(TARGET) ./imem_dmem/dmem.bin
	$(OBJDUMP) -d $(TARGET) > ./imem_dmem/code.dis
	cd imem_dmem && python bin2hex.py

sort: $(SRC_SORT)
	$(CC) $(SRC_SORT) -o $(TARGET) $(CFLAGS) -Ttext 0
	$(OBJCOPY) -O binary $(TARGET) ./imem_dmem/imem.bin
	$(OBJCOPY) -j .data -O binary $(TARGET) ./imem_dmem/dmem.bin
	$(OBJDUMP) -d $(TARGET) > ./imem_dmem/code.dis
	cd imem_dmem && python bin2hex.py

negative: $(SRC_NEGATIVE)
	$(CC) $(SRC_NEGATIVE) -o $(TARGET) $(CFLAGS) -Ttext 0
	$(OBJCOPY) -O binary $(TARGET) ./imem_dmem/imem.bin
	$(OBJCOPY) -j .data -O binary $(TARGET) ./imem_dmem/dmem.bin
	$(OBJDUMP) -d $(TARGET) > ./imem_dmem/code.dis
	cd imem_dmem && python bin2hex.py

fibonacci: $(SRC_FIBONACCI)
	$(CC) $(SRC_FIBONACCI) -o $(TARGET) $(CFLAGS) -Ttext 0
	$(OBJCOPY) -O binary $(TARGET) ./imem_dmem/imem.bin
	$(OBJCOPY) -j .data -O binary $(TARGET) ./imem_dmem/dmem.bin
	$(OBJDUMP) -d $(TARGET) > ./imem_dmem/code.dis
	cd imem_dmem && python bin2hex.py

xor: $(SRC_XOR)
	$(CC) $(SRC_XOR) -o $(TARGET) $(CFLAGS) -Ttext 0
	$(OBJCOPY) -O binary $(TARGET) ./imem_dmem/imem.bin
	$(OBJCOPY) -j .data -O binary $(TARGET) ./imem_dmem/dmem.bin
	$(OBJDUMP) -d $(TARGET) > ./imem_dmem/code.dis
	cd imem_dmem && python bin2hex.py

distance: $(SRC_DISTANCE)
	$(CC) $(SRC_DISTANCE) -o $(TARGET) $(CFLAGS) -Ttext 0
	$(OBJCOPY) -O binary $(TARGET) ./imem_dmem/imem.bin
	$(OBJCOPY) -j .data -O binary $(TARGET) ./imem_dmem/dmem.bin
	$(OBJDUMP) -d $(TARGET) > ./imem_dmem/code.dis
	cd imem_dmem && python bin2hex.py

factorial: $(SRC_FACTORIAL)
	$(CC) $(SRC_FACTORIAL) -o $(TARGET) $(CFLAGS) -Ttext 0
	$(OBJCOPY) -O binary $(TARGET) ./imem_dmem/imem.bin
	$(OBJCOPY) -j .data -O binary $(TARGET) ./imem_dmem/dmem.bin
	$(OBJDUMP) -d $(TARGET) > ./imem_dmem/code.dis
	cd imem_dmem && python bin2hex.py

gcd: $(SRC_GCD)
	$(CC) $(SRC_GCD) -o $(TARGET) $(CFLAGS) -Ttext 0
	$(OBJCOPY) -O binary $(TARGET) ./imem_dmem/imem.bin
	$(OBJCOPY) -j .data -O binary $(TARGET) ./imem_dmem/dmem.bin
	$(OBJDUMP) -d $(TARGET) > ./imem_dmem/code.dis
	cd imem_dmem && python bin2hex.py

# /////clean function
clean:
	-$(RM) $(TARGET) ./imem_dmem/imem.bin ./imem_dmem/imem.hex ./imem_dmem/dmem.bin ./imem_dmem/dmem.hex ./imem_dmem/code.dis
	-del /q $(TARGET) imem_dmem\imem.bin imem_dmem\imem.hex imem_dmem\dmem.bin imem_dmem\dmem.hex imem_dmem\code.dis >nul 2>&1
