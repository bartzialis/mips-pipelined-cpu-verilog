# MIPS Pipelined CPU in Verilog

A 5-stage pipelined MIPS processor implemented in Verilog as part of a Computer Organization and Design course project.

This repository includes the CPU datapath and control implementation, hazard detection and forwarding logic, an assembly test program and a testbench used for functional verification.

## Features

- 5-stage pipelined MIPS CPU
- Verilog implementation of datapath and control
- Hazard detection unit
- Forwarding unit
- Branch and jump handling
- Assembly program execution
- Testbench-based functional verification
- Waveform visualization support with GTKWave

## Repository Structure

mips-pipelined-cpu-verilog

src/
- cpu.v
- control.v
- library.v

program/
- program.asm
- program.hex

simulation/
- testbench.v
- format_kimatomorfon.gtkw
- output.txt

constants.h  
Makefile

## Main Components

### cpu.v

Contains the main 5-stage pipelined CPU implementation including:

- IF/ID, ID/EX, EX/MEM and MEM/WB pipeline registers
- branch and jump control flow handling
- forwarding paths
- hazard detection support

### control.v

Contains the main control unit and ALU control logic responsible for decoding instructions and generating the appropriate control signals for the datapath.

### library.v

Contains reusable Verilog modules used by the CPU implementation such as multiplexers and helper components.

### testbench.v

Provides functional verification of the processor by executing a test program and checking the expected behavior of instructions, stalls and flushes.

### program.asm

Assembly program used to test the processor pipeline behavior.

### program.hex

Machine-code version of the assembly program loaded by the testbench.

## Verification

The processor was verified using the provided testbench.

The simulation output confirms correct execution of instructions as well as hazard-related events such as stalls and flushes.

Examples from the output include:

- instruction PASS checks
- stall detection for load-use hazards
- pipeline flush behavior for branch and jump instructions

## Running the Simulation

The project includes a Makefile for compiling and running the simulation.

Typical usage:

make

If GTKWave is used for waveform inspection, the included .gtkw file can be loaded to visualize relevant signals.

## Academic Context

This project was developed as part of the course:

Computer Organization and Design (ECE219)  
Department of Electrical and Computer Engineering  
University of Thessaly

The course provided an initial framework including the processor datapath diagram, timing constants, a sample assembly program and partial verification infrastructure.

The CPU implementation, control logic, pipeline behavior, hazard handling and module integration were completed as part of the project in order to study and understand the internal operation of a pipelined processor architecture.

## Technologies Used

- Verilog
- MIPS Architecture
- Computer Architecture
- Assembly
- GTKWave
- Icarus Verilog

## License

This project is released under the MIT License.
