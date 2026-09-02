// module csr_file (
//     input  wire        clk,
//     input  wire        rst,
    
//     // Software Read/Write (e.g., using CSRRW instruction)
//     input  wire        csr_write,
//     input  wire [11:0] csr_addr,
//     input  wire [31:0] write_data,
//     output reg  [31:0] read_data,
    
//     // Hardware Interrupt Interface
//     input  wire        ext_irq,      // UART rx_ready pin se connect hoga
//     input  wire        trap_entry,   // Control Unit batayega ke trap shuru ho gaya
//     input  wire        trap_exit,    // Control Unit batayega ke MRET chal gaya
//     input  wire [31:0] current_pc,   // Datapath se old_pc aayega save hone ke liye
    
//     // Outputs to Datapath & FSM
//     output wire [31:0] mtvec_out,
//     output wire [31:0] mepc_out,
//     output wire        trap_pending  // FSM ko batayega ke interrupt aaya hai
// );

//     // M-Mode CSR Registers
//     reg [31:0] mstatus; // Bit 3: MIE (Machine Interrupt Enable)
//     reg [31:0] mie;     // Bit 11: MEIE (Machine External Interrupt Enable)
//     reg [31:0] mip;     // Bit 11: MEIP (Machine External Interrupt Pending)
//     reg [31:0] mtvec;   // Trap Vector Base Address (ISR address)
//     reg [31:0] mepc;    // Exception Program Counter (Wapas aane ka address)

//     // Datapath ko direct values bhejne ke liye
//     assign mtvec_out = mtvec;
//     assign mepc_out  = mepc;

//     // Interrupt Condition: Global Enable (MIE) AND Ext Enable (MEIE) AND Ext Pending (MEIP)
//     assign trap_pending = mstatus[3] & mie[11] & mip[11];

//     // CSR Read Logic (Asynchronous)
//     always @(*) begin
//         case(csr_addr)
//             12'h300: read_data = mstatus;
//             12'h304: read_data = mie;
//             12'h344: read_data = mip;
//             12'h305: read_data = mtvec;
//             12'h341: read_data = mepc;
//             default: read_data = 32'b0;
//         endcase
//     end

//     // CSR Write & Hardware Auto-Update Logic (Synchronous)
//     always @(posedge clk or posedge rst) begin
//         if (rst) begin
//             mstatus <= 32'b0;
//             mie     <= 32'b0;
//             mip     <= 32'b0;
//             mtvec   <= 32'b0;
//             mepc    <= 32'b0;
//         end else begin
//             // 1. Hardware sets Ext Pending Bit when UART fires
//             // 1. Hardware sets Ext Pending Bit when UART fires
//             if (ext_irq) 
//                 mip[11] <= 1'b1;  // Ye pulse ko pakar kar rakh lega
                
//             // 4. Software Writing to CSR
//             else if (csr_write) begin
//                 case(csr_addr)
//                     12'h300: mstatus <= write_data;
//                     12'h304: mie     <= write_data;
//                     // Note: Agar CPU mip mein likh raha hai (e.g. 0), toh flag clear hoga
//                     12'h344: mip     <= write_data; 
//                     12'h305: mtvec   <= write_data;
//                     12'h341: mepc    <= write_data;
//                 endcase
//             end

//             // 2. Hardware Trap Entry (Interrupt lag gaya)
//             if (trap_entry) begin
//                 mepc <= current_pc; // CPU jis instruction par tha, usey save karo
//                 mstatus[3] <= 1'b0; // Global interrupts band kar do (MIE = 0)
//             end 
//             // 3. Hardware Trap Exit (MRET chala diya gaya)
//             else if (trap_exit) begin
//                 mstatus[3] <= 1'b1; // Interrupts wapas on kar do (MIE = 1)
//             end 
//             // 4. Software Writing to CSR (CSRRW instruction)
//             else if (csr_write) begin
//                 case(csr_addr)
//                     12'h300: mstatus <= write_data;
//                     12'h304: mie     <= write_data;
//                     // Note: C code will write 0 to mip[11] to clear the interrupt flag
//                     12'h344: mip     <= write_data; 
//                     12'h305: mtvec   <= write_data;
//                     12'h341: mepc    <= write_data;
//                 endcase
//             end
//         end
//     end
// endmodule


module csr_file (
    input  wire        clk,
    input  wire        rst,
    
    // Software Read/Write
    input  wire        csr_write,
    input  wire [11:0] csr_addr,
    input  wire [31:0] write_data,
    output reg  [31:0] read_data,
    
    // Hardware Interrupt Interface
    input  wire        ext_irq,      
    input  wire        trap_entry,   
    input  wire        trap_exit,    
    input  wire [31:0] current_pc,   
    
    // Outputs to Datapath & FSM
    output wire [31:0] mtvec_out,
    output wire [31:0] mepc_out,
    output wire        trap_pending  
);

    // M-Mode CSR Registers
    reg [31:0] mstatus; // Bit 3: MIE
    reg [31:0] mie;     // Bit 11: MEIE
    reg [31:0] mip;     // Bit 11: MEIP
    reg [31:0] mtvec;   // Trap Vector
    reg [31:0] mepc;    // Exception PC

    assign mtvec_out = mtvec;
    assign mepc_out  = mepc;

    // Interrupt Condition
    assign trap_pending = mstatus[3] & mie[11] & mip[11];

    // CSR Read Logic (Asynchronous)
    always @(*) begin
        case(csr_addr)
            12'h300: read_data = mstatus;
            12'h304: read_data = mie;
            12'h344: read_data = mip;
            12'h305: read_data = mtvec;
            12'h341: read_data = mepc;
            default: read_data = 32'b0;
        endcase
    end

    // CSR Write & Hardware Auto-Update Logic (Synchronous)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            mstatus <= 32'b0;
            mie     <= 32'b0;
            mip     <= 32'b0;
            mtvec   <= 32'b0;
            mepc    <= 32'b0;
        end else begin
            
            // ----------------------------------------------------
            // 1. SOFTWARE WRITES (Lowest Priority)
            // ----------------------------------------------------
            if (csr_write) begin
                case(csr_addr)
                    12'h300: mstatus <= write_data;
                    12'h304: mie     <= write_data;
                    12'h344: mip     <= write_data; // Software clears interrupt here
                    12'h305: mtvec   <= write_data;
                    12'h341: mepc    <= write_data;
                endcase
            end

            // ----------------------------------------------------
            // 2. HARDWARE INTERRUPT SIGNALS (Highest Priority)
            // Ye software ki likhi hui value ko override kar denge
            // ----------------------------------------------------
            
            // UART Interrupt Aagaya
            if (ext_irq) begin
                mip[11] <= 1'b1; 
            end
            
            // Trap mein Entry
            if (trap_entry) begin
                mepc <= current_pc; 
                mstatus[3] <= 1'b0; // Disable global interrupts
            end 
            // Trap se Exit (MRET)
            else if (trap_exit) begin
                mstatus[3] <= 1'b1; // Re-enable global interrupts
            end

        end
    end
endmodule