`timescale 1ns / 1ps
`include "../defines2.vh"
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/11/23 22:57:01
// Design Name: 
// Module Name: eqcmp
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module eqcmp(
	input wire [31:0] a,b,
	input wire [5:0] opD,
	input wire [4:0] rtD,
	output reg y
    );
	always@(*) begin
		case(opD)
			`BEQ : y = (a == b);
			`BNE : y = (a != b);
			`BGTZ : y = ((a[31] == 1'b0) & (a != `ZeroWord));
			`BLEZ : y = ((a[31] == 1'b1) | (a == `ZeroWord));
			`REGIMM_INST : begin
				case(rtD) 
					`BGEZ,`BGEZAL : y = (a[31] == 1'b0);
					`BLTZ,`BLTZAL : y = (a[31] == 1'b1);
					default :y = 1'b0;
				endcase
			end
			default :y = 1'b0;
		endcase
	end
endmodule
