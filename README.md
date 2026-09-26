# ECC_MEMORY: RISC-V Processor with Error Correction Code Memory

## Project Overview

**ECC_MEMORY** is a multi-cycle RISC-V RV32I processor implementation with integrated **Single Error Correction, Double Error Detection (SECDED)** error correction code for memory protection. The project includes a complete CPU design with interrupt handling, UART communication, and comprehensive layered testbench based verification.

### Key Features:

- **RISC-V RV32I ISA Support**: Full 32-bit RISC-V instruction set implementation
- **Multi-Cycle Execution**: Fetch, Fetch2, Decode, Execute, Memory, Memory2, Writeback , Branch, Trap
- **ECC Protection**: SECDED encoder/decoder for data memory with single-bit error correction and double-bit error detection
- **UART Interface**: Serial communication module with 115200 baud rate support
- **Interrupt Handling**: Control Status Register (CSR) based interrupt support with configurable trap vectors
- **Fault Injection**: Built-in fault injection capability for testing ECC robustness
- **Layered Testbench**: Layered TB compliant verification with driver, monitor, scoreboard, and generator components

---

## Directory Structure

### **Main Branch** - Core RTL Design
```
📁 ECC_MEMORY/
├── multicycle_rv32i.v          # Top-level CPU module with ECC wrapper
├── control_unit.v               # Control FSM (5-stage pipeline controller)
├── alu.v                        # Arithmetic Logic Unit
├── imm_gen.v                    # Immediate value generator
├── reg_file.v                   # 32x32 Register file
├── inst_mem.v                   # Instruction memory (SRAM)
├── data_mem.v                   # Data memory (SRAM)
├── ecc_dmem_wrapper.v           # ECC-protected data memory wrapper
├── ecc_status_regs.v            # ECC status register file (memory-mapped 0x5000_0000)
├── error_status_reg.v           # Per-transaction error status tracking
├── secded_encoder.v             # SECDED encoder (data → codeword)
├── secded_decoder.v             # SECDED decoder (codeword → data + syndrome)
├── soc_interconnect.v           # Memory-mapped I/O bus (CPU ↔ RAM/UART/CSR)
├── uart_top.v                   # UART module with RX/TX FIFOs
├── uart_rx_fifo.v               # UART receiver FIFO
├── uart_tx_fifo.v               # UART transmitter FIFO
├── csr_file.v                   # Control Status Registers (mtvec, mepc, mstatus, mie, mip)
├── tb_multicycle_rv32i.v        # Directed testbench with fault injection
└── .gitignore
```

### **Feature/Layered_TB Branch** - LayeredTB-Based Verification
```
📁 feature/layered_tb/
├── top_tb.sv                    # Top-level UVM testbench with scenarios
├── environment.sv               # UVM environment (driver, monitor, scoreboard, generator)
├── cpu_tb_pkg.sv                # Test package with transaction definitions
├── cpu_if.sv                    # CPU interface (virtual interface)
├── transaction.sv               # Transaction class (UART/Fault injection)
├── generator.sv                 # Test scenario generator with sequences
├── driver.sv                    # UVM driver for stimulus generation
├── monitor.sv                   # UVM monitor for observation
├── scoreboard.sv                # UVM scoreboard for prediction & checking
├── observation.sv               # Observation data structure
├── [RTL files]                  # All RTL from main branch (same as main)
```

### **Physical_Design Branch** - Physical Implementation
```
📁 physical_design/
├── rtl/                         # RTL source files for synthesis
├── lib/                         # Process Design Kit (PDK) libraries
├── synthesis/                   # Synthesis scripts and netlist outputs
├── constraints/                 # Timing and placement constraints
└── Equivalence_checking/        # Functional equivalence verification
```

---

## Required Tools & Environment

### Software Requirements:

| Tool | Version | Purpose |
|------|---------|---------|
| **Verilog Simulator** |QuestaSim | RTL simulation & waveform analysis |
| **SystemVerilog Compiler** |QuestaSim |testbench compilation |
| **Synthesis Tool** |Cadence Design Compiler | RTL-to-gate synthesis (physical_design branch) |
| **Verification Tool** | Conformal | Equivalence checking (physical_design branch) |



## How to Compile and Run the Simulation

### Option 1: Directed Testbench (Main Branch)
Fastest approach for quick validation.

#### Step 1: Compile RTL
```bash
cd ECC_MEMORY
vlog *.v  # Compile all Verilog files
```

#### Step 2: Run Simulation
```bash
vsim -c tb_multicycle_rv32i -do "run -all; quit"
```

#### Step 3: View Results
Expected output:
```
==================================================
     DYNAMIC VARIABLE ALTERATION VIA INTERRUPT    
==================================================
...
==================================================
             EXECUTION RESULTS                    
==================================================
x10 (UART Data received) = 0x08000093 (Expected: 0x08000093)
x8  (Current Step Size)  = 0x08000093 (Expected: 0x08000093)
...
>>> SUCCESS: UART RX FIFO DELIVERED 32-BIT WORD! <<<
```

### Option 2: Layered Testbench (Feature/Layered_TB Branch)
Comprehensive verification with test scenarios.

#### Step 1: Switch to Layered TB Branch
```bash
git checkout feature/layered_tb
```

#### Step 2: Compile RTL and Testbench
```bash
vlog +acc *.v                    # Compile RTL with access
vlog +incdir+. *.sv              # Compile SystemVerilog
```

#### Step 3: Run Simulation
```bash
vsim -c top_tb -do "run -all; quit"
```

#### Step 4: Expected Output
```
UVM_INFO @ 0: reporter [RNTST] Running test top_tb...
...
Instr #1 | PC: 0x00 | IR: 0x08000093 | Cycles: 1
Instr #2 | PC: 0x04 | IR: 0x30509073 | Cycles: 5
...
UVM_INFO: Scoreboard: All tests PASSED
UVM_INFO @ 123456ns: reporter [RNTST] $finish called
```


**Scenarios Executed:**
1. **T1: Normal Execution** - Verify x5 counter increments without interrupts
2. **T2: UART Interrupt** - Send 32-bit data via UART, check x10 & x8
3. **T3: ECC Single-Bit** - Inject single error, verify correction
4. **T4: ECC Double-Bit** - Inject double error, verify detection & ISR
5. **T5: Masked Interrupt** - Disable MIE, send data, verify x10 unchanged

---

## How to Reproduce the Reported Results

### Scenario A: CPU Executes Program with Interrupt

1. **Setup:**
   ```bash
   git checkout main
   cd ECC_MEMORY
   ```

2. **Program Loaded in Instruction Memory:**
   - **Boot Code (0x00-0x20):** Sets up interrupt vector, enables interrupts
   - **Background Loop (0x24-0x38):** Infinite loop incrementing x5, loading dummy data
   - **ISR (0x80-0xB0):** Reads UART, checks ECC status, returns via MRET

3. **Run Simulation:**
   ```bash
   vlog *.v
   vsim -c tb_multicycle_rv32i -do "run -all; quit"
   ```

4. **Expected Execution Trace:**
   ```
   Instr #1  | PC: 0x00 | IR: 0x08000093 | Cycles: 5  (ADDI x1, x0, 0x80)
   Instr #2  | PC: 0x04 | IR: 0x30509073 | Cycles: 5  (CSRRW x0, mtvec, x1)
   ...
   Instr #10 | PC: 0x24 | IR: 0x00000293 | Cycles: 5  (ADDI x5, x0, 0) [Loop Start]
   Instr #11 | PC: 0x28 | IR: 0x00128293 | Cycles: 5  (ADDI x5, x5, 1) [Increment]
   ...
   [After UART data injected at ~50,000ns]
   Instr #N  | PC: 0x80 | IR: 0x344015F3 | Cycles: 5  (ISR Entry)
   ...
   Instr #N+5| PC: 0x24 | IR: 0x00000293 | Cycles: 5  (Resume normal program)
   ```

5. **Final Verification:**
   - x10 = 0x08000093 ✓ (UART data received)
   - x8  = 0x08000093 ✓ (Updated by ISR handler)
   - x5  > 0 ✓ (Background loop was running)

### Scenario B: ECC Error Correction in Action

1. **Modify Testbench:**
   ```verilog
   // Uncomment in tb_multicycle_rv32i.v:
   fi_en   = 1'b1;
   fi_mask = 39'h0000000001;  // Single-bit error
   #20;  // Fault active for ~2 cycles
   fi_en   = 1'b0;
   ```

2. **Expected Behavior:**
   - **Memory Read:** Codeword retrieved with 1 bit flipped
   - **SECDED Decoder:** Computes syndrome, identifies error position
   - **Correction:** Flips error bit, recovers original data
   - **Status:** `sb_sticky` = 1, `sb_count` incremented
   - **Data Integrity:** No visible effect (error corrected transparently)

3. **For Double-Bit Error:**
   ```verilog
   fi_mask = 39'h0000000003;  // Two bits flipped
   ```
   - **SECDED Decoder:** Syndrome indicates uncorrectable error (DED)
   - **Action:** Triggers ECC interrupt (ISR at 0x80)
   - **Status:** `db_sticky` = 1, `db_count` incremented
   - **ISR Execution:** Reads error status register at 0x5000_0000, logs count

---

## Key Memory Map

| Address Range | Module | Purpose | Size |
|---|---|---|---|
| 0x0000_0000 - 0x0000_FFFF | `inst_mem` | Instruction Memory (IMEM) | 64 KB |
| 0x1000_0000 - 0x1000_FFFF | `data_mem` (ECC-protected) | Data Memory (DMEM) | 64 KB |
| 0x4000_0000 - 0x4000_FFFF | `uart_top` | UART Control/Data Registers | 64 KB |
| 0x5000_0000 - 0x5000_FFFF | `ecc_status_regs` | ECC Error Status Registers | 64 KB |

### ECC Status Register Layout (0x5000_0000):
- **Offset 0x0:** Single-error sticky flag
- **Offset 0x4:** Double-error sticky flag
- **Offset 0x8:** Single-error count
- **Offset 0xC:** Double-error count

---

## Branch Description

### **main**
- Core RTL design with all modules integrated
- Single directed testbench for functional verification
- Best for: Quick design iteration, basic testing

### **feature/layered_tb**
- UVM-compliant verification environment
- Modular testbench with driver, monitor, scoreboard, generator
- Multiple test scenarios (normal, UART, ECC single/double, masked interrupts)
- Best for: Comprehensive regression testing, formal verification

### **physical_design**
- Synthesis-ready RTL organized for PDK integration
- Constraint files for timing closure
- Place & route artifacts
- Equivalence checking setup
- Best for: FPGA/ASIC implementation, silicon readiness

---

## Debugging Tips



### 1. **Register State Snapshot**
```verilog
// In testbench:
$display("x5=%d, x10=%h, sb_sticky=%b", 
         dut.rf_inst.registers[5], 
         dut.rf_inst.registers[10],
         dut.sb_sticky);
```

### 2. **ISR Execution Verification**
```bash
# Check trap entry/exit signals
vsim -gui tb_multicycle_rv32i
# Zoom to ~50,000ns window
# Observe: trap_pending → trap_entry → ISR_PC → trap_exit
```

### 3. **UART Data Flow**
```verilog
// Trace UART RX FIFO stages
// tb_multicycle_rv32i.v: send_uart_byte() task output
// Expected: 4 bytes assembled into 32-bit word before interrupt
```

---

## Common Issues & Solutions

| Issue | Cause | Solution |
|-------|-------|----------|
| Simulation hangs | Infinite loop in program | Check BEQ offset calculations |
| x10 remains 0 after UART | FIFO not filled with 4 bytes | Send complete 4-byte sequence |
| ECC interrupt not triggered | `mie` register not set correctly | Verify CSR write at 0x18 |
| Waveforms not generated | `-gui` flag missing | Run: `vsim -gui tb_multicycle_rv32i` |
| Compilation errors in `.sv` files | Missing UVM import | Add: `import uvm_pkg::*;` |

---

## References & Documentation

- **RISC-V Specification:** [riscv.org](https://riscv.org)
- **SECDED Algorithm:** Hamming(39,32) code implementation
- **Project GitHub:** [AbdusSamad64/ECC_MEMORY](https://github.com/AbdusSamad64/ECC_MEMORY)

---



**Happy Verifying! 🚀**