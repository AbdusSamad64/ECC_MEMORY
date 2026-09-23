
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

    //ECC interrupt
    input  wire        ecc_double_err_irq,   
    
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
	 
	   // --- NAYA: Edge-Detection Registers ---
    reg ext_irq_prev, ecc_irq_prev;

    // Interrupt Condition
    //assign trap_pending = mstatus[3] & mie[11] & mip[11];

    // AB (UART OR ECC dono, agar mie mein respective bit enabled ho):
    assign trap_pending = mstatus[3] & (|(mie[12:11] & mip[12:11]));

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
				ext_irq_prev <= 1'b0;   // <-- NAYA
            ecc_irq_prev <= 1'b0;   // <-- NAYA

        end else begin
				// --- NAYA: Edge-detect registers, HAR CYCLE update hote hain ---
            ext_irq_prev <= ext_irq;
            ecc_irq_prev <= ecc_double_err_irq;
            
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
            if (ext_irq && !ext_irq_prev) begin
                mip[11] <= 1'b1; 
            end

            //Ecc interrupt agya
            if (ecc_double_err_irq && !ecc_irq_prev) mip[12] <= 1'b1;
            
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
