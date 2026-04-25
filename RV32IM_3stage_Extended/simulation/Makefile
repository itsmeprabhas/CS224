# --- Variables ---
INC_DIR  = ../modules
BFLAGS   = -i $(INC_DIR) -f filelist.txt
TOP_MOD  = tb_pipeline
SNAPSHOT = riscv_sim
MEM_GEN  = ../mem_generator

# Force using make from PATH (fix Windows path issue)
MAKE := make

# Vivado Tools
XVLOG = xvlog
XELAB = xelab
XSIM  = xsim

.PHONY: help clean sort addition negative xor fibonacci distance factorial gcd

help:
	@echo "Usage: make <program_name> (e.g. make addition)"

# Generic Rule for all programs
sort addition negative xor fibonacci distance factorial gcd:
	cd $(MEM_GEN) && $(MAKE) clean
	cd $(MEM_GEN) && $(MAKE) $@
	
	-python -c "import shutil, glob; [shutil.copy(f, '.') for f in glob.glob('../mem_generator/imem_dmem/*.hex')]"

	$(XVLOG) $(BFLAGS)
	$(XELAB) -top $(TOP_MOD) -snapshot $(SNAPSHOT) -debug typical
	
	$(XSIM) $(SNAPSHOT) -runall -log stdout

# Top FPGA Simulation
top: clean
	cd $(MEM_GEN) && $(MAKE) addition
	-python -c "import shutil, glob; [shutil.copy(f, '.') for f in glob.glob('../mem_generator/imem_dmem/*.hex')]"
	$(XVLOG) -d SIMULATION $(BFLAGS) ../modules/top_fpga.v ../modules/tb_top.v ../modules/sev_seg.v
	$(XELAB) -top tb_top -snapshot top_sim -debug typical
	$(XSIM) top_sim -runall -log stdout

clean:
	-rd /s /q xsim.dir .Xil >nul 2>&1
	-del /q xvlog.log xvlog.pb xelab.log xelab.pb xsim.log xsim.jou xsim.pb pipeline.vcd *.hex >nul 2>&1
	-rm -rf xsim.dir/ .Xil/
	-rm -f xvlog.log xvlog.pb xelab.log xelab.pb xsim.log xsim.jou xsim.pb
	-rm -f pipeline.vcd
