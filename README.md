# Pipelined Beta Processor With Hazard Detection

A 32-bit **Beta-style pipelined processor** implemented in Verilog HDL.  
This project builds a processor datapath and control unit from scratch and extends the basic 5-stage pipeline with **forwarding**, **load-use hazard detection**, **stall logic**, **NOP insertion**, and **control-hazard annul logic**.

The design was developed, simulated, and synthesized using **Xilinx Vivado**.

---

## Table of Contents

- [Project Overview](#project-overview)
- [Pipeline Architecture](#pipeline-architecture)
- [Repository Structure](#repository-structure)
- [Top-Level Design](#top-level-design)
- [Instruction Format](#instruction-format)
- [Supported Instruction Classes](#supported-instruction-classes)
- [Datapath Components](#datapath-components)
- [Control Unit](#control-unit)
- [Pipeline Registers](#pipeline-registers)
- [Forwarding Logic](#forwarding-logic)
- [Hazard Detection and Stall Logic](#hazard-detection-and-stall-logic)
- [Control Hazard Handling](#control-hazard-handling)
- [NOP Instruction](#nop-instruction)
- [Reset Behavior](#reset-behavior)
- [Simulation and Verification](#simulation-and-verification)
- [How to Run in Vivado](#how-to-run-in-vivado)
- [Current Limitations](#current-limitations)
- [Future Scope](#future-work)
- [Project Status](#project-status)
- [References](#references)

---

## Project Overview

This project implements a **pipelined Beta processor** in Verilog. The Beta processor is a simple RISC-style educational processor architecture commonly used to understand datapath design, control logic, pipelining, hazards, and processor implementation.

The main goal of this project was to design a working 5-stage pipelined processor with:

- Separate datapath and control unit
- Register file
- ALU
- Instruction memory
- Data memory
- Pipeline registers
- Control-signal pipelining
- Forwarding/bypass logic
- Load-use hazard detection
- Stall mechanism
- NOP insertion
- Branch/jump annul logic

The final design successfully executes pipelined instructions and handles common data and control hazards.

---

## Pipeline Architecture

The processor follows a 5-stage pipeline:

```text
IF  ->  ID/RF  ->  EX  ->  MEM  ->  WB
```

| Stage | Full Name | Purpose |
|---|---|---|
| IF | Instruction Fetch | Fetch instruction from instruction memory using PC |
| ID/RF | Decode / Register Fetch | Decode instruction, read register file, generate control signals |
| EX | Execute | Perform ALU operation or address calculation |
| MEM | Memory Access | Read/write data memory |
| WB | Write Back | Write result back to register file |

Multiple instructions can be active in the processor at the same time, each occupying a different pipeline stage.

---

## Repository Structure

Recommended repository structure:

```text
Beta_Processor/
├── README.md
├── src/
│   ├── Top.v
│   ├── Datapath_unit.v
│   ├── Control_unit.v
│   ├── ALU.v
│   ├── Register_file.v
│   ├── Instruction_Memory.v
│   ├── Data_memory.v
│   ├── Forward_unit.v
│   ├── Hazard_unit.v
│   ├── Register.v
│   ├── Register_1.v
│   ├── Register_2.v
│   ├── Register_4.v
│   ├── Register_en.v
│   ├── PC_4.v
│   ├── PCSEL_mux.v
│   ├── Mux_2to1.v
│   ├── Mux_2to1_5bits.v
│   ├── Adder.v
│   ├── LS_2.v
│   ├── Nor_gate.v
│   └── Sign_Extender.v
└── sim/
    └── testbench files
```

The `src/` folder contains synthesizable RTL design files.  
The `sim/` folder contains simulation testbenches used for functional verification.

---

## Top-Level Design

The top-level module is:

```verilog
Top.v
```

The `Top` module connects the two major processor blocks:

```text
Datapath_unit
Control_unit
```

The datapath sends the current opcode and branch condition signal to the control unit:

```text
opcode
z
```

The control unit generates all control signals and sends them back to the datapath:

```text
alufn
wdsel
pcsel
werf
bsel
asel
mwr
moe
ra2sel
```

Basic top-level flow:

```text
Instruction fetched by datapath
        ↓
Opcode sent to control unit
        ↓
Control signals generated
        ↓
Datapath executes instruction
```

---

## Instruction Format

The processor uses a 32-bit Beta-style instruction format.

Common instruction fields:

```text
OPCODE : IR[31:26]
RC     : IR[25:21]
RA     : IR[20:16]
RB     : IR[15:11]
CONST  : IR[15:0]
```

### Register-Type ALU Format

```text
| OPCODE | RC | RA | RB | unused |
```

Meaning:

```text
Reg[RC] = Reg[RA] operation Reg[RB]
```

Example:

```text
ADD(RA, RB, RC)
Reg[RC] = Reg[RA] + Reg[RB]
```

### Constant-Type ALU Format

```text
| OPCODE | RC | RA | 16-bit constant |
```

Meaning:

```text
Reg[RC] = Reg[RA] operation sign_extended_constant
```

Example:

```text
ADDC(RA, constant, RC)
Reg[RC] = Reg[RA] + sign_extend(constant)
```

### Load/Store Format

```text
| OPCODE | RC | RA | 16-bit constant |
```

For load:

```text
LD(RA, constant, RC)
Reg[RC] = Mem[Reg[RA] + sign_extend(constant)]
```

For store:

```text
ST(RC, constant, RA)
Mem[Reg[RA] + sign_extend(constant)] = Reg[RC]
```

### Branch Format

```text
| OPCODE | RC | RA | 16-bit offset |
```

For branch instructions:

```text
BEQ(RA, offset, RC)
BNE(RA, offset, RC)
```

The processor checks `Reg[RA]`, writes `PC + 4` to `Reg[RC]`, and updates PC depending on branch condition.

### Jump Format

```text
| OPCODE | RC | RA | unused |
```

For jump:

```text
JMP(RA, RC)
Reg[RC] = PC + 4
PC = Reg[RA]
```

---

## Supported Instruction Classes

### Register ALU Instructions

| Instruction | Operation |
|---|---|
| ADD | Addition |
| SUB | Subtraction |
| CMPEQ | Compare equal |
| CMPLT | Signed compare less than |
| CMPLE | Signed compare less than or equal |
| AND | Bitwise AND |
| OR | Bitwise OR |
| XOR | Bitwise XOR |
| XNOR | Bitwise XNOR |
| SHL | Shift left logical |
| SHR | Shift right logical |
| SRA | Shift right arithmetic |

### Constant ALU Instructions

| Instruction | Operation |
|---|---|
| ADDC | Add constant |
| SUBC | Subtract constant |
| CMPEQC | Compare equal with constant |
| CMPLTC | Compare less than with constant |
| CMPLEC | Compare less than or equal with constant |
| ANDC | AND with constant |
| ORC | OR with constant |
| XORC | XOR with constant |
| XNORC | XNOR with constant |
| SHLC | Shift left by constant |
| SHRC | Shift right logical by constant |
| SRAC | Shift right arithmetic by constant |

### Memory Instructions

| Instruction | Operation |
|---|---|
| LD | Load from data memory |
| ST | Store to data memory |
| LDR | PC-relative load |

### Control Instructions

| Instruction | Operation |
|---|---|
| JMP | Jump to register target |
| BEQ | Branch if register is zero |
| BNE | Branch if register is not zero |

---

## Datapath Components

The datapath is implemented in `Datapath_unit.v`.

Major components include:

| Component | Description |
|---|---|
| Program Counter | Holds current instruction address |
| Instruction Memory | Stores/fetches instructions |
| Register File | Stores 32 general-purpose registers |
| Sign Extender | Extends 16-bit constants to 32 bits |
| ALU | Performs arithmetic, logical, comparison, and shift operations |
| Data Memory | Handles load/store memory operations |
| PC Adder | Computes `PC + 4` |
| Branch Adder | Computes branch target |
| Multiplexers | Select ALU operands, PC source, write-back value |
| Pipeline Registers | Store values between pipeline stages |
| Forwarding Unit | Selects forwarded values for operands |
| Hazard Unit | Generates stall for load-use hazards |

---

## Register File

The register file contains 32 registers:

```text
R0 to R31
```

Important behavior:

- Two combinational read ports
- One sequential write port
- Write happens on clock edge
- Register `R31` is hardwired to zero
- Writes to `R31` are ignored

This makes `R31` useful for NOPs and constant-zero operations.

---

## ALU

The ALU supports:

```text
Addition
Subtraction
Comparison
Bitwise logic
Logical shifts
Arithmetic right shift
```

Arithmetic right shift uses signed shifting to preserve the sign bit.

---

## Control Unit

The control unit is implemented in:

```text
Control_unit.v
```

It decodes the opcode and generates the control signals needed by the datapath.

### Main Control Signals

| Signal | Width | Purpose |
|---|---:|---|
| `alufn` | 4-bit | Selects ALU operation |
| `wdsel` | 2-bit | Selects write-back data |
| `pcsel` | 2-bit | Selects next PC |
| `ra2sel` | 1-bit | Selects second register read address |
| `asel` | 1-bit | Selects ALU A input |
| `bsel` | 1-bit | Selects ALU B input |
| `moe` | 1-bit | Memory output enable |
| `mwr` | 1-bit | Memory write enable |
| `werf` | 1-bit | Register file write enable |

---

## Pipeline Registers

Pipeline registers separate the 5 pipeline stages.

### IF/ID Registers

Store:

```text
PC + 4
Fetched instruction
```

### ID/EX Registers

Store:

```text
Decoded instruction
Register operands
Sign-extended constant
Control signals for EX stage
```

### EX/MEM Registers

Store:

```text
ALU result
Store data
Instruction fields
Control signals for MEM stage
```

### MEM/WB Registers

Store:

```text
Write-back value
Instruction fields
Control signals for WB stage
```

The control signals are pipelined with the instruction so that each instruction carries the correct control information as it moves through the pipeline.

---

## Forwarding Logic

The forwarding unit is implemented in:

```text
Forward_unit.v
```

Forwarding is used to solve RAW hazards without stalling when the required value is already available in a later pipeline stage.

The processor supports forwarding from:

```text
EX stage
MEM stage
WB stage
```

to the operand selection path.

Forwarding select signals:

```text
fwdA
fwdB
```

Selection priority:

```text
EX > MEM > WB > Register File
```

This priority ensures that if multiple older instructions target the same destination register, the most recent result is used.

### Example

```text
ADD  R1 = R2 + R3
SUB  R4 = R1 - R5
```

Without forwarding, `SUB` would read an old value of `R1`.

With forwarding, the value produced by `ADD` is sent directly to the dependent instruction before register write-back.

---

## Hazard Detection and Stall Logic

The hazard detection unit is implemented in:

```text
Hazard_unit.v
```

Forwarding cannot solve all hazards. The most important remaining hazard is the **load-use hazard**.

### Load-Use Hazard Example

```text
LD   R1 = MEM[R2 + 0]
ADD  R4 = R1 + R3
```

The loaded value is only available after the memory access stage. The immediately following instruction cannot use it in time without waiting.

When a load-use hazard is detected:

```text
stall = 1
```

### Stall Behavior

When `stall = 1`:

```text
PC is frozen
IF/ID pipeline registers are frozen
A NOP is inserted into ID/EX
Control signals entering EX are set to safe values
```

This inserts a bubble into the pipeline and allows the load instruction to complete safely.

---

## Control Hazard Handling

Control hazards occur due to branches and jumps.

The processor uses a simple speculation strategy:

```text
Default prediction: PC + 4
```

This means the processor assumes the next sequential instruction should execute.

If the branch is not taken, the prediction was correct and no flush is needed.

If the branch is taken or a jump occurs, the already-fetched wrong-path instruction is annulled.

### Annul Logic

The design uses an `annul` signal.

When the PC is redirected due to a taken branch or jump:

```text
annul = 1
```

The fetched wrong-path instruction is replaced with a NOP.

This prevents wrong-path instructions from changing the architectural state.

---

## NOP Instruction

The processor uses:

```verilog
32'h83FFF800
```

as a NOP.

This corresponds to:

```text
ADD(R31, R31, R31)
```

Since `R31` always reads as zero and writes to `R31` are ignored, this instruction has no effect.

NOPs are inserted during:

```text
Load-use stalls
Branch/jump annul conditions
```

---

## Reset Behavior

The design uses an **active-low asynchronous reset**.

```text
reset = 0 -> reset active
reset = 1 -> normal operation
```

Register modules use:

```verilog
always @(posedge clk or negedge reset)
```

This means the processor state is cleared immediately when reset is pulled low.

---

## Simulation and Verification

The processor was verified through Vivado simulation.

Testbenches were developed for:

```text
Register file
Instruction memory
Data memory
ALU
Control unit
Top-level processor
Forwarding logic
Load-use hazard stall
Control hazard annul
```

### Verified Functional Cases

The following behaviors were verified:

```text
ADD, SUB, AND, OR, XOR execution
Immediate/constant ALU instructions
Load and store instructions
Branch and jump behavior
ALU-to-ALU forwarding
ALU-to-constant forwarding
ALU-to-store forwarding
Load-use stall insertion
Branch taken annul
Branch not-taken fall-through
JMP target redirection
```

The design was also synthesized successfully in Vivado.

---

## How to Run in Vivado

1. Open Xilinx Vivado.
2. Create a new RTL project.
3. Add all files from the `src/` folder as design sources.
4. Add files from the `sim/` folder as simulation sources.
5. Set `Top.v` as the synthesis top module.
6. Select the required testbench as the simulation top module.
7. Run behavioral simulation.
8. Run synthesis.

---

## Suggested Vivado Source Setup

Design sources:

```text
src/*.v
```

Simulation sources:

```text
sim/*.v
```

Top module for synthesis:

```text
Top
```

---

## Current Limitations

- Instruction and data memories are simple Verilog memory arrays.
- Memory contents are mainly initialized through testbenches.
- No external memory interface is currently implemented.
- No cache is implemented.
- No interrupt or exception handling is implemented.
- The design is primarily an educational RTL processor.
- ASIC/GDSII implementation is planned as a future extension.

---

## Future Work

Possible future improvements:

```text
Refactor memory into external instruction/data memory interfaces
Integrate SRAM macros for ASIC implementation
Run RTL-to-GDSII flow using OpenLane/OpenROAD
Add formal verification
Add more complete ISA support
Add exception and interrupt handling
Improve automated testbench coverage
Add waveform screenshots and synthesis reports
Add timing, power, and area analysis
```

---

## Project Status

| Task | Status |
|---|---|
| RTL datapath design | Completed |
| Control unit design | Completed |
| Pipeline registers | Completed |
| Register file | Completed |
| ALU | Completed |
| Data memory | Completed |
| Instruction memory | Completed |
| Forwarding logic | Completed |
| Hazard detection | Completed |
| Load-use stall logic | Completed |
| Control hazard annul logic | Completed |
| Vivado simulation | Completed |
| Vivado synthesis | Completed |
| GitHub upload | Completed |
| RTL-to-GDSII | Planned |

---

---

## References

This project was developed with reference to the MIT Computation Structures course material.

1. **MIT Computation Structures**  
   Main course website:  
   https://computationstructures.org/

2. **Building the Beta**  
   Used as a reference for the Beta instruction set architecture, instruction formats, datapath organization, register file behavior, ALU instructions, constant instructions, memory instructions, branch instructions, and jump instruction behavior.  
   https://computationstructures.org/lectures/beta/beta.html

3. **Pipelining the Beta**  
   Used as a reference for the 5-stage pipelined Beta architecture, pipeline registers, data hazards, stall logic, bypass/forwarding logic, load-use stalls, speculation, and branch annul logic.  
   https://computationstructures.org/lectures/pbeta/pbeta.html

4. **MIT Computation Structures Course Material**  
   The course material was used to understand the design of digital systems, including combinational logic, sequential circuits, processor datapaths, control logic, and pipelined processor implementation.  
   https://computationstructures.org/
