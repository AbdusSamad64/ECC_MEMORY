module soc_interconnect (
    // CPU Interface (Master)
    input  wire [31:0] cpu_addr,
    input  wire [31:0] cpu_wdata,
    input  wire        cpu_mem_read,
    input  wire        cpu_mem_write,
    output wire [31:0] cpu_rdata,

    // ECC RAM Interface (Slave 1)
    output wire        ram_re,
    output wire        ram_we,
    output wire [31:0] ram_addr,
    output wire [31:0] ram_wdata,
    input  wire [31:0] ram_rdata,

    // UART Interface (Slave 2)
    output wire        uart_re,
    output wire        uart_we,
    output wire [31:0] uart_addr,
    output wire [31:0] uart_wdata,
    input  wire [31:0] uart_rdata,

    // ECC Status Interface (Slave 3)   <-- NAYA BLOCK
    output wire        ecc_status_re,
    output wire        ecc_status_we,
    output wire [31:0] ecc_status_addr,
    input  wire [31:0] ecc_status_rdata
);

    // 1. Address Decoding Logic (Memory Map)
    // RAM Address Range: 0x0000_0000 to 0x0000_FFFF
    wire is_ram  = (cpu_addr[31:16] == 16'h0000); 
    
    // UART Address Range: 0x4000_0000 to 0x4000_00FF
    wire is_uart = (cpu_addr[31:8] == 24'h400000); 

    // ECC error
    wire is_ecc_status = (cpu_addr[31:8] == 24'h500000);   // 0x5000_0000 - 0x5000_00FF

    // 2. Write Enable Routing
    assign ram_we  = cpu_mem_write & is_ram;
    assign uart_we = cpu_mem_write & is_uart;
    assign ecc_status_we  = cpu_mem_write & is_ecc_status;   // <-- NAYA


    // 3. Read Enable Routing
    assign ram_re  = cpu_mem_read & is_ram;
    assign uart_re = cpu_mem_read & is_uart;
    assign ecc_status_re = cpu_mem_read & is_ecc_status;

    // 4. Address and Data Routing (CPU to Slaves)
    assign ram_addr   = cpu_addr;
    assign ram_wdata  = cpu_wdata;

    assign uart_addr  = cpu_addr;
    assign uart_wdata = cpu_wdata;

    assign ecc_status_addr = cpu_addr;                        // <-- NAYA

    // 5. Read Data MUX (Slaves to CPU)
    assign cpu_rdata = is_ram  ? ram_rdata  :
                       is_uart ? uart_rdata : 
                       is_ecc_status  ? ecc_status_rdata   :   // <-- NAYA
                       32'h0000_0000; // Default zero (bus fault handling yahan add ho sakti hai)

endmodule