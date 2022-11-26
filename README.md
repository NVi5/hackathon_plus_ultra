# hackathon base
Project's qpf can be found in quartus_project/ dir.  
FPGA's pins are pre-assigned already.  
All sources are located in src/ directory.  

# simulation
Examples of comp.do and sim.do files can be found in sim/ dir.  
When you run Modelsim from Quartus, just run:
```tcl
  do ../../../sim/comp.do
  do ../../../sim/sim.do
```

You can differentiate compilation for simulation in Modelsim/Riviera-PRO, by closing code in clauses:
```verilog
`ifdef SIMULATION
    <code_only_for_simulation>
`endif
```
SIMULATION define is added in ModelSim compilation scripts.  
It is used mainly for simulation runtime reduction purposes.

# project's structure
+ top
  + reset_release
  + uart_wrapper
    + tx_fifo
    + uart_tx
    + uart_rx
    + rx_fifo
  + reset_phy_pipe
  + mac_wrapper
    + mac_rx
    + rx_fifo
    + tx_fifo
    + mac_tx
  + main (put your code under this module)
    + task_manager
      + protocol
    + debug_port
    
# main
Task interface to prepared top
+ task_manager - should take care of control of 
different exercises being executed and communication bypass to ethernet FIFOs interfaces to protocol instance
  + protocol - should implement MHP protocol support and serve the data according to tasks
+ debug_port - can reports traffic or other events to UART, by defaults reports 2 bytes every 30s: start delimiter, watchdog codebyte.
Have in mind that by default USB UART works at 115200bps, so it is much slower compared to ethernet communication.  
In design is only being sped up for simulation purposes (with abovementioned defines).

# coding style
Can be suited up to your needs. In base project:
- two spaces are used in place of tabs
- one space is used after assignment
- spacings in declaration are kinda aligned (as far as it makes sense)
- newline at the end the file
- top level pins are CAPITALIZED
- internal interface signals has direction prefixes
- default timescale 1ns/ns
- default nettype is assumed to be wire,
- module interfaces are assigned at the end of the module