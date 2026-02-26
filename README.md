# AXI4-Lite Master/Slave IP Core & Comprehensive Verification

This project provides a complete **AXI4-Lite** protocol IP Core suite written in Verilog, featuring a Master controller, a Slave module, and a comprehensive testbench. The design focuses on simplicity, reliability with built-in Timeout protection, and full support for error response signals.

## 📌 Components Overview

### 1. AXI4-Lite Master (`AXI_master.v`)

The Master controller converts user-level requests (User Interface) into standard AXI4-Lite transactions.

* **Features:**
  * State-machine (FSM) based design with independent Read and Write channels.
  * **Timeout Mechanism:** Automatically terminates transactions and reports a `SLVERR` (2'b10) if the Slave fails to respond within a configurable number of clock cycles (`TIMEOUT_VAL`).
  * Simple User Interface with `busy`, `done`, and `resp` status signals.

### 2. AXI4-Lite Slave (`AXI_slave.v`)

The Slave module simulates a peripheral device with internal storage registers.

* **Features:**
  * Includes 4 internal 32-bit registers (`slv_reg0` to `slv_reg3`).
  * **Byte Strobe Support:** Supports the `WSTRB` signal for precise byte-level writing to registers.
  * **Address Decoding:** Validates addresses. If an invalid address is accessed, the Slave responds with a `DECERR` (2'b11) and returns dummy data `0xDEADDEAD`.

### 3. Comprehensive Testbench (`AXI_tb.v`)

A robust verification environment with 18 distinct phases to ensure high code coverage and protocol reliability.

* **Test Scenarios:**
  * Basic Read/Write and full address space scanning.
  * Byte mask (`WSTRB`) coverage for all 16 possible combinations.
  * **Fault Injection:** Simulates delays in Ready/Valid signals to verify handshake robustness.
  * **Timeout Testing:** Simulates a hung Slave to verify the Master's self-recovery mechanism.
  * **Stress Test:** Executes 500 constrained random transactions to check stability.

## 🛠 Technical Parameters

| Parameter | Description | Default Value | 
| ----- | ----- | ----- | 
| `C_M_AXI_ADDR_WIDTH` | Address bus width | 32-bit | 
| `C_M_AXI_DATA_WIDTH` | Data bus width | 32-bit | 
| `TIMEOUT_VAL` | Transaction timeout threshold (Master) | 255 clocks | 

## 🚀 Getting Started

### Prerequisites

* A Verilog simulator (Icarus Verilog, Vivado, ModelSim, or QuestaSim).
* Waveform viewer (GTKWave for Icarus Verilog users).

### Running the Simulation (Using Icarus Verilog)

* Compile the source files
iverilog -o axi_sim AXI_master.v AXI_slave.v AXI_tb.v

* Run the simulation
vvp axi_sim

### Verification Phases
The testbench prints detailed logs for each phase:
* Initial Access: Verifies the very first transaction.
* Address Scan: Scans valid addresses from 0x0 to 0xC.
* Decerr Handling: Verifies responses when accessing non-existent addresses.
* Flow Control: Challenges handshakes by delaying READY signals.
* Timeout Recovery: Confirms the Master doesn't hang when a Slave is unresponsive.
* Random Stress: Validates performance under random load.
