`include "../defines2.vh"
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/10/23 15:21:30
// Design Name: 
// Module Name: maindec
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


module maindec(
	input wire[5:0] op,
	input wire[5:0] funct,
	input wire[4:0] rs,
	input wire[4:0] rt,
	output wire memtoreg,memwrite,
	output wire branch,alusrc,
	output wire[1:0] regdst,
	output wire regwrite,
	output wire jump,
	output wire hilo_write,
	output wire jbral,
	output wire jr,
	output wire cp0_write,
	output reg is_invalid,
	output wire hilotoreg,
	output wire cp0toreg,
	output reg memread,
	output wire [1:0] mfhi_lo
    );

	assign hilotoreg = (op == 6'b000000) && (funct ==6'b010000|| funct == 6'b010010);
	assign cp0toreg = ~(|(op ^ 6'b010000)) & ~(|(rs ^ 5'b00000));
	wire mfhi,mflo;
	assign mfhi = !(op ^ `R_TYPE) & !(funct ^ `MFHI);
	assign mflo = !(op ^ `R_TYPE) & !(funct ^ `MFLO);
	assign mfhi_lo = {mfhi,mflo};

	
	reg[11:0] controls;
	assign {regwrite,regdst,alusrc,branch,memwrite,memtoreg,jump,hilo_write,jbral,jr,cp0_write} = controls;
	always @(*) begin
		memread <= 1'b0; 
		is_invalid <= 1'b0;
		case (op)
			`R_TYPE:
				case (funct)
					`ADD,`ADDU,`SUB,`SUBU,`SLT,`SLTU,
					`AND,`NOR,`OR,`XOR,
					`SLLV,`SLL,`SRAV,`SRA,`SRLV,`SRL,
					`MFHI,`MFLO:						controls <= 12'b1_01_000000000;
					`DIV,`DIVU,`MULT,`MULTU,
					`MTHI,`MTLO:						controls <= 12'b0_00_000001000;
					`JR:								controls <= 12'b0_00_000000010;
					`JALR:								controls <= 12'b1_01_000000110;
					//自陷指令
					`BREAK,`SYSCALL:                    controls <= 12'b0_00_000000000;
					default:  begin
						controls <= 12'b000000000000;
						is_invalid <= 1'b1;
					end
				endcase
			// I-type
			`ADDI,`ADDIU,`SLTI,`SLTIU,
			`ANDI,`LUI,`ORI,`XORI:		controls <= 12'b1_00_100000000;
			`BEQ,`BNE,`BGTZ,`BLEZ:		controls <= 12'b0_00_010000000;
			`REGIMM_INST:
				case (rt)
					`BGEZ,`BLTZ:		controls <= 12'b0_00_010000000;
					`BGEZAL,`BLTZAL:	controls <= 12'b1_10_010000100;
					default:  begin
						controls <= 12'b000000000000;
						is_invalid <= 1'b1;
					end
				endcase
			`LB,`LBU,`LH,`LHU,`LW:begin
						controls <= 12'b1_00_100100000;
						memread <= 1'b1;
						end
			`SB,`SH,`SW:				controls <= 12'b0_00_101000000;
			// J-type
			`J:		controls <= 12'b0_00_000010000;
			`JAL:	controls <= 12'b1_10_000010100;
			//for exception
			`SPECIAL3_INST:
				case(rs)
					`MTC0:controls <= 12'b0_00_000000001;
        			`MFC0:controls <= 12'b1_00_000000000;
        			`ERET:controls <= 12'b0_00_000000000;
					default:  begin
						controls <= 12'b000000000000;
						is_invalid <= 1'b1;
					end
				endcase    
			6'b111111:
				case(funct)
					6'b000000:
						controls <= 12'b1_01_000000000;
				endcase
			default:  begin
					controls <= 12'b000000000000;
					is_invalid <= 1'b1;
			end
		endcase
	end
endmodule