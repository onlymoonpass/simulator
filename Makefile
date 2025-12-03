CXXSRC = $(shell find ./back-end/ -name "*.cpp")
CXXSRC += $(shell find ./front-end/ -name "*.cpp")
CXXSRC += $(shell find ./diff/ -name "*.cpp")
CXXSRC += $(shell find ./mmu/ -name "*.cpp")
# CXXSRC += ./rv_simu_mmu.cpp
CXXSRC += ./rv_simu_mmu_v2.cpp # cpp file with main function
CXXINCLUDE = -I./include/
CXXINCLUDE += -I./back-end/include/
CXXINCLUDE += -I./back-end/EXU/include/
CXXINCLUDE += -I./back-end/tools/include/
CXXINCLUDE += -I./diff/include/
CXXINCLUDE += -I./front-end/
CXXINCLUDE += -I./mmu/include/

# for verilator
USE_VERILATOR      = 1
MODULE_NAME        = rename_top
OBJ_DIR            = ./obj_dir
VERILATOR_FILELIST = v_src/filelist_verilator.f

ifeq ($(USE_VERILATOR), 1)
CXXINCLUDE   += -I$(CONDA_PREFIX)/share/verilator/include
CXXINCLUDE   += -I${OBJ_DIR}
CXXINCLUDE   += -I$(CONDA_PREFIX)/include
VERILATOR_OPT = -L${OBJ_DIR} -l${MODULE_NAME} -lverilated -lpthread
endif

ifeq ($(USE_VERILATOR), 1)
COMPILER = $(CONDA_PREFIX)/bin/x86_64-conda-linux-gnu-g++ -std=c++20
else
COMPILER = g++
endif
##############################################################
MEM_DIR=./baremetal
IMG=./baremetal/memory

default: $(CXXSRC) 
	${COMPILER} $(CXXINCLUDE) $(CXXSRC) -O3 -g -march=native -flto -funroll-loops -mtune=native ${VERILATOR_OPT}

cov: $(CXXSRC) 
	g++ $(CXXINCLUDE) $(CXXSRC) -O0 --coverage 

run: 
	./a.out $(IMG)

clean:
	rm -f a.out
	rm -rf ./baremetal/memory
	rm -rf ./baremetal/test.code
	rm -rf obj_dir
	rm -rf *.vcd

gdb:
	${COMPILER} $(CXXINCLUDE) $(CXXSRC) -g  ${VERILATOR_OPT}
	gdb --args ./a.out $(IMG)

# 生成 verilog 对应的 c++ 文件
verilator:
	verilator --cc -f ${VERILATOR_FILELIST} --prefix ${MODULE_NAME} --trace -CFLAGS -fPIE --build

.PHONY: all clean mem run

