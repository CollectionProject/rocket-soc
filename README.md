System-On-Chip template based on Rocket-chip (RISC-V ISA). VHDL implementation.
=====================

This repository contains all neccessary files to build ready-to-use 
top-level of the System-on-Chip with the CPU and common set of the peripheries
for some well-known development FPGA boards. 

## What is Rocket-chip and [RISC-V ISA](http://www.riscv.org)?

RISC-V (pronounced "risk-five") is a new instruction set architecture (ISA) 
that was originally designed to support computer architecture research and 
education and is now set become a standard open architecture for industry 
implementations under the governance of the RISC-V Foundation. RISC-V was 
originally developed in the Computer Science Division of the EECS Department
at the University of California, Berkeley.

Parameterized generator of the Rocket-chip can be found here:
[https://github.com/ucb-bar](https://github.com/ucb-bar)
   

## Implemented functionality (v1.0)

Use branch *v1.0* to get verified and simplified revision of the SOC with
the general set of peripheries and without GNSS related functionality.

    $ git clone -b v1.0 https://github.com/sergeykhbr/riscv_vhdl.git

Version 1.0 **doesn't require _RF front-end_ mezzanine card** and simplify
demonstration procedure. v1.0 branch implements:

- Pre-configured single *"Rocket"* core (Verilog) integrated in our VHDL top
  level.
- System-on-Chip top-level with the common set of peripheries with the 
  AMBA AXI4 interfaces: GPIO, LEDs, UART, IRQ controller etc.
- Plug'n-Play support.
- Configuration and constraint files for ML605 (Virtex6) and KC705 (Kintex7) 
  FPGA boards.
- Bit-files for ML605 and KC705 boards.
- Pre-built ROM images with the BootLoader and FW-image. FW-image is copied
  into internal SRAM during boot-stage.
- *"Hello World"* example.

## Final result without modification of code

* LEDs sequential switching;
* UART outputs Plug'n'Play configuraiton message with 1 sec period
  (115200 baud).

```
    Boot . . .OK
    # RISC-V: Rocket-Chip demonstration design
    # HW version: 0x20160115
    # Target technology: Virtex6
    # AXI4: slv0: GNSS Sensor Ltd.    Boot ROM
    #    0x00000000...0x00001FFF, size = 8 KB
    # AXI4: slv1: GNSS Sensor Ltd.    FW Image ROM
    #    0x00100000...0x0013FFFF, size = 256 KB
    # AXI4: slv2: GNSS Sensor Ltd.    Internal SRAM
    #    0x10000000...0x1007FFFF, size = 512 KB
    # AXI4: slv3: GNSS Sensor Ltd.    Generic UART
    #    0x80001000...0x80001FFF, size = 4 KB
    # AXI4: slv4: GNSS Sensor Ltd.    Generic GPIO
    #    0x80000000...0x80000FFF, size = 4 KB
    # AXI4: slv5: GNSS Sensor Ltd.    Interrupt Controller
    #    0x80002000...0x80002FFF, size = 4 KB
    # AXI4: slv6: GNSS Sensor Ltd.    GNSS Engine
    #    0x80003000...0x80003FFF, size = 4 KB
    # AXI4: slv7: GNSS Sensor Ltd.    Dummy device
    #    0x00000000...0x00000FFF, size = 4 KB
    # AXI4: slv8: GNSS Sensor Ltd.    Plug'n'Play support
    #    0xFFFFF000...0xFFFFFFFF, size = 4 KB
```

## Implemented functionality (master -> v2.0)

    $ git clone https://github.com/sergeykhbr/riscv_vhdl.git

  Current *master* version adds new functionality to the v1.0 branch:

- Portable asyncronous FIFO implementation allowing to connect modules to the 
  System BUS from a separate clock domains (ADC clock domain):
     * Fast Search Engines 
     * GNSS Engine
- Ethernet MAC 10/100Mb (gigabit MAC by request) with the debug function (EDCL)
  that allows redirect UDP requests directly on system BUS.
- Debug Support Unit (DSU) provides access to all processors CSRs.
- GNSS modules are distributeds as a netlist files (in \*.ngc format) or as 
  a stubs.
- By default GNSS is disabled in *confg_common.vhd* file that makes *master*
  version very close to the *v1.0* branch by its functionality.
- Using *master* trunk without *RF front-end* is **possible** in TEST_MODE.
  Enabling TEST_MODE in a final 2.0 version will require manual switching
  of the configuration jumper (*i_int_clkrf*) on board.

## How to build and run FPGA bitfile on ML605 board (Virtex6)

- Open project file for Xilinx ISE14.7 *prj/ml605/rocket_soc.xise*.
- Edit two configuration constants *CFG_SIM_BOOTROM_HEX* and 
  *CFG_SIM_FWIMAGE_HEX* in file **work/comfig_common.vhd** with the correct
  string values accordingly with your project directory.
- Generate programming file and load it into FPGA.
- You should see a single output message in uart port as follow (use button 
  "*Center*" to reset system and repead message):

```
    Boot . . .OK
    ADC clock not found. Enable DIP int_rf.
```
 
- **Switch "ON" DIP[0]** (i_int_clkrf) to enable *TEST Mode* that enables
  ADC clock generation as sys_clk/4.
- Now you should see plug'n'play information messages with 1 second period.
- For Xilinx KC705 board use Vivado project  *prj/kc705/rocket_chip.xpr*.


## Simulation with the ModelSim

1. Create new project.
2. Create libraries with the following names using ModelSim **libraries** view:
     * techmap
     * commonlib
     * rocketlib
     * gnsslib
     * work (was created by default)
3. Using project browser create the same folders structure like in the 
   *riscv_vhdl*. On the top level of the project should be folders matching
   to the libraries names and they should include all exist sub-folders.
4. Add existing files into the proper folder using righ-click menu of the
   project browser in ModelSim.
     * Add all files ".._tech.vhd" and ".._inferred.vhd"
     * Don't include files ".._v6.vhd", ".._k7.vhd" etc.
5. Make sure that all files in libraries folder will be compiled into appropriate
   VHDL library. **_By default all files will be compiled into 'work' library_** 
   and you should fix that assignments on appropriate ones.
6. Use *config_common.vhd* and *config_msim.vhd* to configurate target for the
   behaviour simulation.
7. Use *work/tb/rocket_soc_tb.vhd* to run simulation.
8. Default firmware does the following things:
     * Switching LEDs;
     * Print information into UART;
     * Check Interupt controller
     * and other.


## How to build your own firmware

  You can find step-by-step instruction of how to build your own
toolchain on [riscv.org](http://riscv.org/software-tools/). If you would like
to use pre-build GCC binary files and libraries you can download it here:
 
   [Ubuntu GNU GCC toolchain RV64IMA (256MB)](http://www.gnss-sensor.com/index.php?LinkID=1013)

  Feature of this GCC build is the configuration *RV64IMA* (without FPU).
Default toolchain configuration generates makefile with hardware FPU that 
makes *libc* library incompatible with the *_-msoft-float_* compiler key.

  Just after you download the toolchain unpack it and set environment variable
as follows:

    $ tar -xzvf gnu-toolchain-rv64ima.tar.gz gnu-toolchain-rv64ima
    $ export PATH=/home/your_path/gnu-toolchain-rv64ima/bin:$PATH


## RISC-V Firmware example for the Rocket-chip

  So, now you can build your own firmware image and create hex-file that
can be directly used in VHDL SOC (*rocket_soc/work/config_common.vhd*) to 
initialize Boot ROM image (FW ROM is the additional option).

  RISC-V "Hello World" example is available in *./rocket_soc/fw/boot* 
directory. It implements general functionality for the Rocket-chip based 
system, such as:
- Initial Rocket-chip boot-up
- Interrupt handling setup
- UART output
- LED switching
- Target type auto-detection (RTL simulatation or not)
- Coping image from FW ROM to SRAM using libc method *memcpy()*

To build this example use:

    $ cd rocket_soc/fw/boot/makefiles
    $ make
    $ cd ../linuxbuild/bin

Opened directory contains the following files:
- _bootimage_       - elf-file (not used by SOC).
- _bootimage.dump_  - disassembled file for the verification.
- *_bootimage.hex_* - HEX-file for the Boot ROM intialization.

Specify the correct path to file *_bootimage.hex_* in SOC configuraiton file
for this open file *rocket_soc/work/config_common.vhd* and set the correct 
value to *_CFG_SIM_BOOTROM_HEX_* constant.

I hope your are also here and run your firmware on RISC-V system.


## Doxygen project documentation

[http://sergeykhbr.github.io/riscv_vhdl/](http://sergeykhbr.github.io/riscv_vhdl/)

