// Code your design here
`timescale 1ns / 1ps
// Define opcodes for each instruction
module isa_definitions;
    // Instruction opcodes (4-bit)
    parameter LOAD  = 4'b0000;
    parameter STORE = 4'b0001;
    parameter ADD   = 4'b0010;
    parameter SUB   = 4'b0011;
    parameter AND   = 4'b0100;
    parameter OR    = 4'b0101;
    parameter JMP   = 4'b0110;

    // Instruction format
    // 8-bit instruction: [7:4] - opcode, [3:0] - operand (register or address)
    // Example: LOAD R1 -> 8'b0000_0001 (LOAD opcode and operand for R1)
    
    // Sample Instructions (for reference)
    wire [7:0] instr_load_r1  = {LOAD, 4'b0001}; // LOAD R1
    wire [7:0] instr_store_r2 = {STORE, 4'b0010}; // STORE R2
    wire [7:0] instr_add_r1_r2 = {ADD, 4'b0001}; // ADD R1 to R2
    wire [7:0] instr_sub_r3_r4 = {SUB, 4'b0011}; // SUB R3 and R4
    wire [7:0] instr_and_r1_r2 = {AND, 4'b0001}; // AND R1 and R2
    wire [7:0] instr_or_r1_r3  = {OR, 4'b0011};  // OR R1 and R3
    wire [7:0] instr_jmp_addr  = {JMP, 4'b1000}; // JMP to address (example: 8)

endmodule
`timescale 1ns / 1ps

module ALU (
    input [3:0] A,             // Operand A (4-bit)
    input [3:0] B,             // Operand B (4-bit)
    input [3:0] opcode,        // ALU operation code
    output reg [3:0] result,   // Result of the ALU operation
    output reg zero_flag       // Zero flag for conditional branching
);

    // ALU Operation
    always @(*) begin
        case (opcode)
            4'b0010: result = A + B;          // ADD
            4'b0011: result = A - B;          // SUB
            4'b0100: result = A & B;          // AND
            4'b0101: result = A | B;          // OR
            default: result = 4'b0000;        // Default to zero
        endcase
        
        // Set zero flag
        zero_flag = (result == 4'b0000) ? 1'b1 : 1'b0;
    end
endmodule

`timescale 1ns / 1ps

module Register (
    input clk,                  // Clock signal
    input reset,                // Reset signal
    input [3:0] data_in,        // Data to be loaded into the register
    input load,                 // Load enable signal
    output reg [3:0] data_out   // Output data
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            data_out <= 4'b0000; // Reset register to 0
        end else if (load) begin
            data_out <= data_in; // Load data if load is high
        end
    end
endmodule

`timescale 1ns / 1ps

module ProgramCounter (
    input clk,                  // Clock signal
    input reset,                // Reset signal
    input [3:0] new_address,    // New address for jump
    input pc_load,              // Load new address signal (for jump)
    output reg [3:0] pc         // Current program counter value
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pc <= 4'b0000;         // Reset PC to 0
        end else if (pc_load) begin
            pc <= new_address;     // Load new address for jump
        end else begin
            pc <= pc + 4'b0001;    // Increment PC by 1
        end
    end
endmodule
 
`timescale 1ns / 1ps


module Memory (
    input clk,                       // Clock signal
    input [3:0] address,             // Memory address (4-bit)
    input [3:0] write_data,          // Data to write
    input mem_write,                 // Write enable signal
    input mem_read,                  // Read enable signal
    output reg [7:0] read_data       // Data read from memory
);

    reg [7:0] mem [15:0];            // Define a 4-bit x 16 memory

    // Memory write operation
    always @(posedge clk) begin
        if (mem_write) begin
            mem[address] <= {4'b0000, write_data}; // Write data to memory
        end
    end

    // Memory read operation
    always @(*) begin
        if (mem_read) begin
            read_data = mem[address];  // Read data from memory
        end else begin
            read_data = 8'b0;
        end
    end
endmodule


`timescale 1ns / 1ps

module Processor (
    input clk,                    // Clock signal
    input reset                   // Reset signal
);

    // Internal signals
    reg [3:0] opcode;             // Opcode from instruction
    reg [3:0] operand;            // Operand from instruction
    wire [3:0] alu_result;        // Output of the ALU
    wire zero_flag;               // Zero flag from ALU
    reg [3:0] pc_value;           // Program counter value
    reg pc_load;                  // PC load signal for jump
    reg [3:0] reg_data_out;       // Data output from register
  reg [7:0] memory_data;        // Data read from memory
    wire [3:0] write_data;        // Data to write into memory or registers
    
    // Control signals
    reg mem_read, mem_write;
    reg reg_load, alu_enable;

    // Instantiate modules
    ProgramCounter PC (
        .clk(clk),
        .reset(reset),
        .new_address(operand),
        .pc_load(pc_load),
        .pc(pc_value)
    );

    Memory MEM (
        .clk(clk),
        .address(pc_value),
        .write_data(write_data),
        .mem_write(mem_write),
        .mem_read(mem_read),
        .read_data(memory_data)
    );

    Register REG (
        .clk(clk),
        .reset(reset),
        .data_in(alu_result),
        .load(reg_load),
        .data_out(reg_data_out)
    );

    ALU ALU (
        .A(reg_data_out),
        .B(operand),
        .opcode(opcode),
        .result(alu_result),
        .zero_flag(zero_flag)
    );

    // Instruction Fetch and Decode
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            opcode <= 4'b0000;
            operand <= 4'b0000;
        end else if (mem_read) begin
            opcode <= memory_data[7:4]; // Upper 4 bits for opcode
            operand <= memory_data[3:0]; // Lower 4 bits for operand
        end
    end

    // Control Unit - Generate Control Signals Based on Opcode
    always @(*) begin
        // Default values for control signals
        mem_read = 1'b0;
        mem_write = 1'b0;
        reg_load = 1'b0;
        alu_enable = 1'b0;
        pc_load = 1'b0;

        case (opcode)
            4'b0000: begin // LOAD
                mem_read = 1'b1;
                reg_load = 1'b1;
            end
            4'b0001: begin // STORE
                mem_write = 1'b1;
            end
            4'b0010: begin // ADD
                alu_enable = 1'b1;
                reg_load = 1'b1;
            end
            4'b0011: begin // SUB
                alu_enable = 1'b1;
                reg_load = 1'b1;
            end
            4'b0110: begin // JMP
                pc_load = 1'b1;
            end
            default: begin
                // No operation
            end
        endcase
    end

    // Data Path Logic
    assign write_data = reg_data_out;  // For STORE instruction
endmodule
