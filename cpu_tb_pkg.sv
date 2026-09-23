// =====================================================================
// cpu_tb_pkg.sv
// SystemVerilog classes must be visible to each other at compile time,
// so they're all pulled into one package via `include, in dependency
// order (transaction/observation types first, environment last).
// tb_top imports this package instead of compiling the classes loose.
// =====================================================================
package cpu_tb_pkg;

    `include "transaction.sv"
    `include "observation.sv"
    `include "generator.sv"
    `include "driver.sv"
    `include "monitor.sv"
    `include "scoreboard.sv"
    `include "environment.sv"

endpackage