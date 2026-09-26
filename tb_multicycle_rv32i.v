// `timescale 1ns / 1ps

// module tb_multicycle_rv32i;

//     reg clk;
//     reg rst;
    
//     // --- NAYE PINS (UART Physical Interface) ---
//     reg  rx_pin;
//     wire tx_pin;

//     // Overall Instrumentation Variables
//     integer cycle_count = 0;
//     integer instr_count = 0;

//     // Per-Instruction Cycle Tracking Variables
//     integer per_instr_cycles  = 0;
//     integer current_instr_num = 0;
//     reg [31:0] current_pc     = 0;
//     reg [31:0] current_ir     = 0;

//     // Instantiate Top Module
//     multicycle_rv32i dut (
//         .clk(clk),
//         .rst(rst),
//         .rx_pin(rx_pin), // Connected to testbench reg
//         .tx_pin(tx_pin)  // Connected to testbench wire
//     );

//     // 100MHz Clock Generation (10ns period)
//     always #5 clk = ~clk;

//     // Combined Cycle & Per-Instruction Tracking Logic
//     always @(posedge clk) begin
//         if (!rst) begin
//             cycle_count      <= cycle_count + 1;
//             per_instr_cycles <= per_instr_cycles + 1;

//             // FSM entering FETCH state (3'b000) -> Start of a new instruction
//             if (dut.ctrl_inst.state == 3'b000) begin
//                 instr_count <= instr_count + 1;

//                 // Display cycle breakdown for the instruction that JUST completed
//                 if (current_instr_num > 0) begin
//                     $display("Instr #%0d | PC: 0x%08h | IR: 0x%08h | Cycles Taken: %0d", 
//                              current_instr_num, current_pc, current_ir, per_instr_cycles);
//                 end

//                 per_instr_cycles  <= 1; // Cycle 1 of current instruction
//                 current_instr_num <= current_instr_num + 1;
//             end

//             // FSM entering DECODE state (3'b001) -> Capture PC and IR for logging
//             if (dut.ctrl_inst.state == 3'b001) begin
//                 current_pc <= dut.old_pc;
//                 current_ir <= dut.ir;
//             end
//         end
//     end
    
//     // ========================================================
//     // UART SERIAL DATA INJECTION TASK
//     // ========================================================
//     // Ye task 100MHz clock aur 115200 baud rate ke hisaab se 
//     // exact timing par serial bits rx_pin par bheje ga.
//     localparam CLOCKS_PER_BIT = 100_000_000 / 115200; // ~868 clocks
//     localparam BIT_PERIOD     = CLOCKS_PER_BIT * 10;  // 8680 ns per bit
    
//     task send_uart_byte;
//         input [7:0] data;
//         integer i;
//         begin
//             $display("[%0t] UART TESTBENCH: Sending byte 0x%0h ('%c')", $time, data, data);
            
//             // Start Bit (LOW)
//             rx_pin = 0;
//             #(BIT_PERIOD);
            
//             // Data Bits (LSB First)
//             for (i = 0; i < 8; i = i + 1) begin
//                 rx_pin = data[i];
//                 #(BIT_PERIOD);
//             end
            
//             // Stop Bit (HIGH)
//             rx_pin = 1;
//             #(BIT_PERIOD);
            
//             $display("[%0t] UART TESTBENCH: Byte sent completely.", $time);
//         end
//     endtask

//     // ========================================================
//     // MAIN TEST SEQUENCE
//     // ========================================================
//     initial begin
//         clk = 0;
//         rst = 1;
//         rx_pin = 1; // UART Idle state is HIGH

//         // Preload memory with machine code instructions:
//         // 1. ADDI x1, x0, 10  -> x1 = 10
//         dut.imem_inst.mem[0] = 32'h00A00093;
//         // 2. ADDI x2, x0, 20  -> x2 = 20
//         dut.imem_inst.mem[1] = 32'h01400113;
//         // 3. ADD  x3, x1, x2  -> x3 = 30
//         dut.imem_inst.mem[2] = 32'h002081B3;
//         // 4. SW   x3, 32(x0)  -> Mem[32] = 30
//         dut.imem_inst.mem[3] = 32'h02302023;
//         // 5. LW   x4, 32(x0)  -> x4 = Mem[32] = 30
//         dut.imem_inst.mem[4] = 32'h02002203;
//         // 6. BEQ  x1, x1, 8   -> Jump +8 bytes (skips instruction 7)
//         dut.imem_inst.mem[5] = 32'h00108463;
//         // 7. ADDI x5, x0, 99  -> Skipped by branch
//         dut.imem_inst.mem[6] = 32'h06300293;
//         // 8. SUB  x6, x3, x1  -> x6 = 30 - 10 = 20
//         dut.imem_inst.mem[7] = 32'h40118333;

//         // Release reset
//         #15;
//         rst = 0;

//         $display("==================================================");
//         $display("          PER-INSTRUCTION CYCLE LOG               ");
//         $display("==================================================");

//         // Run simulation cycles for the CPU instructions
//         #400;

//         // Display Register / Memory Results
//         $display("==================================================");
//         $display("             PROCESSOR EXECUTION RESULTS          ");
//         $display("==================================================");
//         $display("x1 (Expected: 10)     = %d", dut.rf_inst.registers[1]);
//         $display("x2 (Expected: 20)     = %d", dut.rf_inst.registers[2]);
//         $display("x3 (Expected: 30)     = %d", dut.rf_inst.registers[3]);
//         $display("x4 (Expected: 30)     = %d", dut.rf_inst.registers[4]);
//         $display("x5 (Expected: 0)      = %d [Skipped by Branch]", dut.rf_inst.registers[5]);
//         $display("x6 (Expected: 20)     = %d", dut.rf_inst.registers[6]);
//         $display("Mem[32] (Expected: 30)= %d", dut.dmem_inst.mem[8]);
//         $display("==================================================");

//         if (dut.rf_inst.registers[1] == 10 &&
//             dut.rf_inst.registers[2] == 20 &&
//             dut.rf_inst.registers[3] == 30 &&
//             dut.rf_inst.registers[4] == 30 &&
//             dut.rf_inst.registers[5] == 0  &&
//             dut.rf_inst.registers[6] == 20 &&
//             dut.dmem_inst.mem[8]      == 30) begin
//             $display(">>> SUCCESS: ALL MULTI-CYCLE TESTS PASSED <<<");
//         end else begin
//             $display(">>> FAILURE: INCORRECT REGISTER/MEMORY VALUES <<<");
//         end

//         // --------------------------------------------------------
//         // EXAMPLE: HOW TO TEST UART INTERRUPT (Uncomment to use)
//         // --------------------------------------------------------
//         // $display("\n--- INJECTING UART DATA ---");
//         // send_uart_byte(8'h41); // Sends ASCII 'A' (0x41)
//         // #1000; // Wait a bit for CPU to process interrupt
        
//         $finish;
//     end

// endmodule


// `timescale 1ns / 1ps

// module tb_multicycle_rv32i;

//     reg clk;
//     reg rst;
    
//     // --- NAYE PINS (UART Physical Interface) ---
//     reg  rx_pin;
//     wire tx_pin;

//     // Overall Instrumentation Variables
//     integer cycle_count = 0;
//     integer instr_count = 0;

//     // Per-Instruction Cycle Tracking Variables
//     integer per_instr_cycles  = 0;
//     integer current_instr_num = 0;
//     reg [31:0] current_pc     = 0;
//     reg [31:0] current_ir     = 0;

//     // Instantiate Top Module
//     multicycle_rv32i dut (
//         .clk(clk),
//         .rst(rst),
//         .rx_pin(rx_pin), 
//         .tx_pin(tx_pin)  
//     );

//     // 100MHz Clock Generation (10ns period)
//     always #5 clk = ~clk;

//     // Combined Cycle & Per-Instruction Tracking Logic
//     always @(posedge clk) begin
//         if (!rst) begin
//             cycle_count      <= cycle_count + 1;
//             per_instr_cycles <= per_instr_cycles + 1;

//             if (dut.ctrl_inst.state == 3'b000) begin
//                 instr_count <= instr_count + 1;

//                 if (current_instr_num > 0) begin
//                     $display("Instr #%0d | PC: 0x%08h | IR: 0x%08h | Cycles Taken: %0d", 
//                              current_instr_num, current_pc, current_ir, per_instr_cycles);
//                 end

//                 per_instr_cycles  <= 1; 
//                 current_instr_num <= current_instr_num + 1;
//             end

//             if (dut.ctrl_inst.state == 3'b001) begin
//                 current_pc <= dut.old_pc;
//                 current_ir <= dut.ir;
//             end
//         end
//     end
    
//     // ========================================================
//     // UART SERIAL DATA INJECTION TASK
//     // ========================================================
//     localparam CLOCKS_PER_BIT = 100_000_000 / 115200; // ~868 clocks
//     localparam BIT_PERIOD     = CLOCKS_PER_BIT * 10;  // 8680 ns per bit
    
//     task send_uart_byte;
//         input [7:0] data;
//         integer i;
//         begin
//             $display("[%0t] UART TESTBENCH: Sending byte 0x%0h ('%c')", $time, data, data);
//             rx_pin = 0; // Start Bit
//             #(BIT_PERIOD);
            
//             for (i = 0; i < 8; i = i + 1) begin
//                 rx_pin = data[i]; // Data Bits
//                 #(BIT_PERIOD);
//             end
            
//             rx_pin = 1; // Stop Bit
//             #(BIT_PERIOD);
//             $display("[%0t] UART TESTBENCH: Byte sent completely.", $time);
//         end
//     endtask

//     // ========================================================
//     // MAIN TEST SEQUENCE
//     // ========================================================
//     initial begin
//         clk = 0;
//         rst = 1;
//         rx_pin = 1; // UART Idle state is HIGH

//         // -------------------------------------------------------------
//         // PRELOAD MEMORY (Interrupt Test Code)
//         // -------------------------------------------------------------
        
//         // --- BOOT CODE ---
//         // 1. ADDI x1, x0, 0x80   (ISR Address)
//         dut.imem_inst.mem[0] = 32'h08000093;
//         // 2. CSRRW x0, mtvec, x1 
//         dut.imem_inst.mem[1] = 32'h30509073;
        
//         // 3. LUI x1, 1           (Set MEIE bit)
//         dut.imem_inst.mem[2] = 32'h000010B7;
//         // 4. SRLI x1, x1, 1      
//         dut.imem_inst.mem[3] = 32'h0010D093;
//         // 5. CSRRW x0, mie, x1   
//         dut.imem_inst.mem[4] = 32'h30409073;
        
//         // 6. ADDI x1, x0, 8      (Set MIE bit)
//         dut.imem_inst.mem[5] = 32'h00800093;
//         // 7. CSRRW x0, mstatus, x1
//         dut.imem_inst.mem[6] = 32'h30009073;
        
//         // 8. BEQ x0, x0, 0       (Infinite Loop at PC=0x1C)
//         dut.imem_inst.mem[7] = 32'h00000063;


//         // --- ISR CODE (At PC = 0x80, Array Index = 32) ---
//         // --- ISR CODE (At PC = 0x80, Array Index = 32) ---
//         // 32. LUI x2, 0x40000    (UART Base Address)
//         dut.imem_inst.mem[32] = 32'h40000137;
        
//         // 33. LW x10, 0(x2)      (Read UART Data into x10. Is se UART ka internal flag ghirega)
//         dut.imem_inst.mem[33] = 32'h00012503;
        
//         // --- Naya: Clear CSR Pending Flag ---
//         // 34. CSRRW x0, mip, x0  (mip register ko completely 0 kar do)
//         dut.imem_inst.mem[34] = 32'h34401073;

//         // 35. MRET               (Return from interrupt)
//         dut.imem_inst.mem[35] = 32'h30200073;

//         // Release reset
//         #15;
//         rst = 0;

//         $display("==================================================");
//         $display("          UART RX INTERRUPT TEST START            ");
//         $display("==================================================");

//         // CPU ko thora time do taake wo apna boot code chala le
//         #1000; 

//         // -------------------------------------------------------------
//         // INJECT DATA VIA UART
//         // -------------------------------------------------------------
//         // Hum testbench se character 'U' (0x55) bhejenge.
//         // 0x55 binary mein 01010101 hota hai, iski waveform boht achi nazar aati hai.
//         send_uart_byte(8'h55);

//         // CPU aur UART ko time do taake ISR poora ho jaye
//         #10000; 

//         $display("==================================================");
//         $display("             INTERRUPT EXECUTION RESULTS          ");
//         $display("==================================================");
//         $display("x10 (Expected: 85 (0x55)) = %d (0x%h)", dut.rf_inst.registers[10], dut.rf_inst.registers[10]);
//         $display("==================================================");

//         if (dut.rf_inst.registers[10] == 32'h55) begin
//             $display(">>> SUCCESS: UART INTERRUPT TRIGGERED AND DATA RECEIVED! <<<");
//         end else begin
//             $display(">>> FAILURE: x10 DOES NOT CONTAIN 0x55 <<<");
//         end

//         $finish;
//     end

// endmodule



`timescale 1ns / 1ps

module tb_multicycle_rv32i;

    reg clk;
    reg rst;
    
    // --- Physical UART Interface ---
    reg  rx_pin;
    wire tx_pin;
	 
			 // --- NAYA ---
	 reg        fi_en;
	 reg [38:0] fi_mask;

    // Instrumentation Variables
    integer cycle_count = 0;
    integer instr_count = 0;
    integer per_instr_cycles  = 0;
    integer current_instr_num = 0;

    integer print_allow_counter = 0; // Naya variable
    
    reg [31:0] current_pc     = 0;
    reg [31:0] current_ir     = 0;
    reg [31:0] last_printed_pc = 32'hFFFF_FFFF;

    multicycle_rv32i dut (
        .clk(clk),
        .rst(rst),
        .rx_pin(rx_pin), 
        .tx_pin(tx_pin),
		  .fi_en(fi_en),           // <-- normal port connection
        .fi_mask(fi_mask)
    );

    always #5 clk = ~clk;

    // Tracking Logic with Spam Prevention
    always @(posedge clk) begin
        if (!rst) begin
            cycle_count      <= cycle_count + 1;
            per_instr_cycles <= per_instr_cycles + 1;

            // if (dut.ctrl_inst.state == 3'b000) begin
            //     instr_count <= instr_count + 1;

            //     if (current_instr_num > 0) begin
            //         if (current_pc != last_printed_pc) begin
            //             // Spam Prevention: Normal program ki loop PC 0x20 se 0x28 ke darmian hai
            //             if (instr_count < 50 || current_pc > 32'h28) begin
            //                 $display("Instr #%0d | PC: 0x%08h | IR: 0x%08h | Cycles Taken: %0d", 
            //                          current_instr_num, current_pc, current_ir, per_instr_cycles);
            //             end else if (instr_count == 50) begin
            //                 $display("... [CPU IS DOING NORMAL MATH IN BACKGROUND] ...");
            //                 $display("... [WAITING FOR UART INTERRUPT] ...");
            //             end
            //             last_printed_pc <= current_pc;
            //         end
            //     end

            //     per_instr_cycles  <= 1; 
            //     current_instr_num <= current_instr_num + 1;
            // end

            if (dut.ctrl_inst.state == 3'b000) begin
                instr_count <= instr_count + 1;

                if (current_instr_num > 0) begin
                    if (current_pc != last_printed_pc) begin
                        
                        // NAYI LOGIC: Agar PC 0x28 se bahar nikla (ISR gaya), toh counter ko 10 set kar do
                        if (current_pc > 32'h78) begin
                            print_allow_counter = 10; // MRET ke baad 10 insts dekhne ke liye
                        end

                        // Spam Prevention Logic updated
                        if (instr_count < 50 || current_pc > 32'h78 || print_allow_counter > 0) begin
                            
                            $display("Instr #%0d | PC: 0x%08h | IR: 0x%08h | Cycles Taken: %0d", 
                                     current_instr_num, current_pc, current_ir, per_instr_cycles);
                            
                            // Agar CPU wapas normal background task (<=0x28) mein agaya hai toh counter kam karo
                            if (current_pc <= 32'h78 && instr_count >= 50) begin
                                print_allow_counter = print_allow_counter - 1;
                            end

                        end else if (instr_count == 50) begin
                            $display("... [CPU IS DOING NORMAL MATH IN BACKGROUND] ...");
                            $display("... [WAITING FOR UART INTERRUPT] ...");
                        end
                        last_printed_pc <= current_pc;
                    end
                end

                per_instr_cycles  <= 1; 
                current_instr_num <= current_instr_num + 1;
            end

            if (dut.ctrl_inst.state == 3'b001) begin
                current_pc <= dut.old_pc;
                current_ir <= dut.ir;
            end
        end
    end
    
    // UART SERIAL DATA INJECTION TASK
    localparam CLOCKS_PER_BIT = 100_000_000 / 115200; 
    localparam BIT_PERIOD     = CLOCKS_PER_BIT * 10;  
    
    task send_uart_byte;
        input [7:0] data;
        integer i;
        begin
            $display("[%0t] --- UART HARDWARE SENDS BYTE 0x%0h ---", $time, data);
            rx_pin = 0; // Start Bit
            #(BIT_PERIOD);
            
            for (i = 0; i < 8; i = i + 1) begin
                rx_pin = data[i]; 
                #(BIT_PERIOD);
            end
            
            rx_pin = 1; // Stop Bit
            #(BIT_PERIOD);
            $display("[%0t] --- UART DATA TRANSMISSION COMPLETE ---", $time);
        end
    endtask

    // initial begin
    //     clk = 0;
    //     rst = 1;
    //     rx_pin = 1; 

    //     // -------------------------------------------------------------
    //     // PRELOAD MEMORY (Normal CPU Task + Interrupt Handler)
    //     // -------------------------------------------------------------
    //     // --- 1. BOOT CODE (Setup Interrupts) ---
    //     dut.imem_inst.mem[0] = 32'h08000093; // 0x00: ADDI x1, x0, 0x80 (ISR Address)
    //     dut.imem_inst.mem[1] = 32'h30509073; // 0x04: CSRRW x0, mtvec, x1 
    //     dut.imem_inst.mem[2] = 32'h000010B7; // 0x08: LUI x1, 1 
    //     dut.imem_inst.mem[3] = 32'h0010D093; // 0x0c: SRLI x1, x1, 1 
    //     dut.imem_inst.mem[4] = 32'h30409073; // 0x10: CSRRW x0, mie, x1 
    //     dut.imem_inst.mem[5] = 32'h00800093; // 0x14: ADDI x1, x0, 8
    //     dut.imem_inst.mem[6] = 32'h30009073; // 0x18: CSRRW x0, mstatus, x1

    //     // --- 2. NORMAL PROGRAM (Background Counter Task) ---
    //     dut.imem_inst.mem[7] = 32'h00000293; // 0x1C: ADDI x5, x0, 0 (x5 = 0)
    //     dut.imem_inst.mem[8] = 32'h00128293; // 0x20: ADDI x5, x5, 1 (x5++) <-- LOOP START
    //     dut.imem_inst.mem[9] = 32'h00228313; // 0x24: ADDI x6, x5, 2 (Dummy math task)
    //     dut.imem_inst.mem[10]= 32'hFE000ce3; // 0x28: BEQ x0, x0, -8 (Jump back to 0x20)

    //     // --- 3. INTERRUPT SERVICE ROUTINE (At PC = 0x80) ---
    //     dut.imem_inst.mem[32] = 32'h40000137; // 0x80: LUI x2, 0x40000 
    //     dut.imem_inst.mem[33] = 32'h00012503; // 0x84: LW x10, 0(x2) (Read UART Data)
    //     dut.imem_inst.mem[34] = 32'h34401073; // 0x88: CSRRW x0, mip, x0 (Clear Pending Flag)
    //     dut.imem_inst.mem[35] = 32'h30200073; // 0x8c: MRET (Return to Normal Program)

    //     // Release reset
    //     #15;
    //     rst = 0;

    //     $display("==================================================");
    //     $display("          ASYNCHRONOUS INTERRUPT TEST             ");
    //     $display("==================================================");

    //     // CPU normal addition start kar dega
    //     #500; 

    //     // CPU jab addition mein busy hai, humein achanak data bhejna hai!
    //     // Is baar 'A' ki bajaye 'Z' (0x5A) bhejte hain.
    //     send_uart_byte(8'h5A);

    //     // ISR chalne aur dobara loop mein aane ka wait
    //     #20000; 

    //     $display("==================================================");
    //     $display("             EXECUTION RESULTS                    ");
    //     $display("==================================================");
    //     $display("x10 (UART Data received) = 0x%h (Expected: 0x5a)", dut.rf_inst.registers[10]);
    //     $display("x5 (Background Counter)  = %d (Normal program was running!)", dut.rf_inst.registers[5]);
    //     $display("==================================================");

    //     if (dut.rf_inst.registers[10] == 32'h5A && dut.rf_inst.registers[5] > 0) begin
    //         $display(">>> SUCCESS: CPU HANDLED INTERRUPT AND RESUMED NORMAL TASK! <<<");
    //     end else begin
    //         $display(">>> FAILURE <<<");
    //     end

    //     $finish;
    // end


    initial begin
        clk = 0;
        rst = 1;
        rx_pin = 1; 
		  fi_en   = 1'b0;      // <-- NAYA: shuru mein disabled, koi fault nahi
		  fi_mask = 39'b0;     // <-- NAYA
			
			
		  dut.dmem_inst.u_dmem.mem[64] = 39'h0;  // 0x100/4 = 64, ek known encoded-zero value
        // -------------------------------------------------------------
        // PRELOAD MEMORY (Dynamic Counter Scenario)
        // -------------------------------------------------------------
        
        // --- BOOT CODE ---
        dut.imem_inst.mem[0] = 32'h08000093; // 0x00: ADDI x1, x0, 0x80      -> x1 = 0x80 (ISR addr)
        dut.imem_inst.mem[1] = 32'h30509073; // 0x04: CSRRW x0, mtvec, x1    -> mtvec = 0x80

        dut.imem_inst.mem[2] = 32'h000010B7; // 0x08: LUI x1, 1              -> x1 = 0x1000 (bit 12)
        dut.imem_inst.mem[3] = 32'h000011B7; // 0x0c: LUI x3, 1              -> x3 = 0x1000
        dut.imem_inst.mem[4] = 32'h0011D193; // 0x10: SRLI x3, x3, 1         -> x3 = 0x0800 (bit 11)
        dut.imem_inst.mem[5] = 32'h0030E0B3; // 0x14: OR x1, x1, x3          -> x1 = 0x1800 (bit11 | bit12)
        dut.imem_inst.mem[6] = 32'h30409073; // 0x18: CSRRW x0, mie, x1      -> mie = 0x1800

        dut.imem_inst.mem[7] = 32'h00800093; // 0x1c: ADDI x1, x0, 8         -> x1 = 8
        dut.imem_inst.mem[8] = 32'h30009073; // 0x20: CSRRW x0, mstatus, x1  -> mstatus[3] = 1

        // --- NORMAL BACKGROUND PROGRAM (ab yahan se, index +2 shift hua) ---
        //dut.imem_inst.mem[9]  = 32'h00000293; // 0x24: ADDI x5, x0, 0
        //dut.imem_inst.mem[10] = 32'h00100413; // 0x28: ADDI x8, x0, 1

        //dut.imem_inst.mem[11] = 32'h008282B3; // 0x2c: ADD x5, x5, x8   <-- LOOP START
        //dut.imem_inst.mem[12] = 32'hfe000ee3; // 0x30: BEQ x0, x0, -4   (wapas 0x2c par)
		  
		  // Naya loop (ek extra register x17 use karke, RAM address 0x100 se dummy read karo)
			dut.imem_inst.mem[9]  = 32'h00000293; // 0x24: ADDI x5, x0, 0
			dut.imem_inst.mem[10] = 32'h00100413; // 0x28: ADDI x8, x0, 1
			dut.imem_inst.mem[11] = 32'h10000913; // 0x2c: ADDI x18, x0, 0x100   <-- NAYA: dummy address x18=0x100

			dut.imem_inst.mem[12] = 32'h008282B3; // 0x30: ADD x5, x5, x8       <-- LOOP START (address shift hua)
			dut.imem_inst.mem[13] = 32'h00092883; // 0x34: LW x17, 0(x18)        <-- NAYA: dummy read (fault-injection ka target)
			dut.imem_inst.mem[14] = 32'hfe000ce3; // 0x38: BEQ x0, x0, -8        <-- wapas 0x30 par

        // --- ISR CODE (At PC = 0x80, Array Index = 32) ---
        // --- ISR CODE (0x80 onwards) ---
        // --- ISR CODE (0x80 onwards) ---

        // 0x80: CSRRW x11, mip, x0
        dut.imem_inst.mem[32] = 32'h344015F3;

        // 0x84: SRLI x13, x11, 12
        dut.imem_inst.mem[33] = 32'h00C5D693;

        // 0x88: ANDI x13, x13, 1
        dut.imem_inst.mem[34] = 32'h0016F693;

        // 0x8c: BNE x13, x0, +20   -> ECC_HANDLER (0xA0) par jao
        dut.imem_inst.mem[35] = 32'h00069A63;

        // --- UART_HANDLER ---
        // 0x90: LUI x2, 0x40000
        dut.imem_inst.mem[36] = 32'h40000137;
        // 0x94: LW x10, 0(x2)
        dut.imem_inst.mem[37] = 32'h00012503;
        // 0x98: ADD x8, x0, x10
        dut.imem_inst.mem[38] = 32'h00a00433;
        // 0x9c: BEQ x0, x0, +16   -> MRET tak jump (ECC_HANDLER + status-read skip)
        dut.imem_inst.mem[39] = 32'h00000863;   // offset ab +16 hai kyunke ECC_HANDLER lamba ho gaya

        // --- ECC_HANDLER (0xA0) ---
        // 0xa0: ADDI x9, x0, 1     -> x9 = 1 (flag)
        dut.imem_inst.mem[40] = 32'h00100493;
        // 0xa4: LUI x14, 0x50000   -> x14 = ECC status base
        dut.imem_inst.mem[41] = 32'h50000737;
        // 0xa8: LW x15, 8(x14)     -> x15 = single_err_count
        dut.imem_inst.mem[42] = 32'h00872783;
        // 0xac: LW x16, 12(x14)    -> x16 = double_err_count
        dut.imem_inst.mem[43] = 32'h00C72803;

        // --- COMMON EXIT ---
        // 0xb0: MRET
        dut.imem_inst.mem[44] = 32'h30200073;

        // Release reset
        #15;
        rst = 0;

        $display("==================================================");
        $display("     DYNAMIC VARIABLE ALTERATION VIA INTERRUPT    ");
        $display("==================================================");

        // 1. CPU normal addition start karega (Step = +1)
        #50000; 

        // 2. CPU +1 mein busy hai, hum 32-bit instruction ke 4 bytes bhejte hain:
        //    0x93 0x00 0x00 0x08  => 0x08000093
        send_uart_byte(8'h93);
        send_uart_byte(8'h00);
        send_uart_byte(8'h00);
        send_uart_byte(8'h08);

        // 3. Wapas aane aur naye step size se thora calculate karne ka wait
        #300000; 

        $display("==================================================");
        $display("             EXECUTION RESULTS                    ");
        $display("==================================================");
        $display("x10 (UART Data received) = 0x%h (Expected: 0x08000093)", dut.rf_inst.registers[10]);
        $display("x8  (Current Step Size)  = 0x%h (Expected: 0x08000093)", dut.rf_inst.registers[8]);
        $display("x5  (Final Counter Val)  = %d", dut.rf_inst.registers[5]);
        $display("==================================================");


        //$display("x15 (Single-err count) = %0d", dut.rf_inst.registers[15]);
        //$display("x16 (Double-err count) = %0d", dut.rf_inst.registers[16]);

        if (dut.rf_inst.registers[10] == 32'h08000093 &&
            dut.rf_inst.registers[8]  == 32'h08000093) begin
            $display(">>> SUCCESS: UART RX FIFO DELIVERED 32-BIT WORD! <<<");
        end else begin
            $display(">>> FAILURE <<<");
        end
		  
		  
        // =============================================================
        // NAYA: ECC FAULT-INJECTION TESTS (UART test ke bilkul baad)
        // =============================================================
        $display("==================================================");
        $display("          ECC FAULT INJECTION TEST                ");
        $display("==================================================");

        // --- TEST A: SINGLE-BIT ERROR ---
        $display("[%0t] Injecting SINGLE-bit error...", $time);
        fi_en   = 1'b1;
        fi_mask = 39'h0000000001;   // sirf 1 bit flip
        #20;                      // itna wait taake CPU koi LOAD zaroor kare (background loop mein LOAD nahi hai abhi, isliye neeche note dekho)
        fi_en   = 1'b0;
        #500;

        $display("Single-err sticky = %0d", dut.sb_sticky);
        $display("Single-err count  = %0d", dut.sb_count);

        // --- TEST B: DOUBLE-BIT ERROR ---
        $display("[%0t] Injecting DOUBLE-bit error...", $time);
        fi_en   = 1'b1;
        fi_mask = 39'h0000000003;   // 2 bits flip
        #20;
        fi_en   = 1'b0;
        #500;

        $display("Double-err sticky = %0d", dut.db_sticky);
        $display("Double-err count  = %0d", dut.db_count);
        $display("x9 (ECC flag)     = %0d", dut.rf_inst.registers[9]);

        $finish;
    end
endmodule