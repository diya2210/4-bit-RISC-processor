`timescale 1ns / 1ps

module Processor_tb;

    // Clock and reset signals
    reg clk;
    reg reset;

    // Instantiate the Processor
    Processor uut (
        .clk(clk),
        .reset(reset)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // Generate a clock with 10ns period
    end

    // Test Procedure
    initial begin
        // Initialize signals and reset processor
        reset = 1;
        #10 reset = 0; // Deassert reset after 10ns
        
        // Load instructions into memory manually
        // Assuming each instruction is 8-bit, format: [opcode][operand]
        uut.MEM.mem[0] = 8'b0000_0001; // LOAD R1 (Load value to register R1)
        uut.MEM.mem[1] = 8'b0010_0010; // ADD R1, #2 (Add immediate value 2 to R1)
        uut.MEM.mem[2] = 8'b0001_0001; // STORE R1 (Store R1 value back to memory)
        uut.MEM.mem[3] = 8'b0110_0000; // JMP to address 0 (Unconditional jump to start)
        
        // Displaying values at each clock cycle
        $monitor("Time: %0dns, PC: %d, Instruction: %b, Register R1: %b, Memory[1]: %b",
                 $time, uut.PC.pc, uut.MEM.read_data, uut.REG.data_out, uut.MEM.mem[1]);

        // Simulation duration
        #100;
        
        // Check results (based on expected outputs)
        $display("Final Register R1 value: %b", uut.REG.data_out);
        $display("Final Memory[1] value: %b", uut.MEM.mem[1]);
        
        // End simulation
        $stop;
    end

endmodule
