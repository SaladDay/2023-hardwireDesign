`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/11/02 14:52:16
// Design Name: 
// Module Name: alu
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
`include "defines2.vh"

module alu(
	input wire clk,rst,
	input wire[31:0] a,b,  //操作数a,b
	input wire [4:0] alucontrolE,
	input wire [4:0] sa,
	input wire [63:0] hilo_in, //读取的HI、LO寄存器的值
	input wire [31:0] cp0_rdata, //读取的CP0寄存器的值
	input wire is_except, //用于触发异常时控制除法相关刷新
	output wire[63:0] hilo_out, //全部的出口
	// output reg[31:0] result,
	output wire mul_stall,  
	output wire div_stall,   //除法的流水线暂停控制
	output wire overflow     //溢出判断
	// output wire zero
    );

	reg double_sign; //凑运算结果的双符号位，处理整型溢出
	reg [31:0] result;
	assign overflow = (alucontrolE==`ADD_CONTROL || alucontrolE==`SUB_CONTROL) & (double_sign ^ result[31]); 

	//div
	wire div_sign,div_valid;
	assign div_sign = (alucontrolE == `DIV_CONTROL);
	assign div_valid = (alucontrolE == `DIV_CONTROL || alucontrolE == `DIVU_CONTROL);
	wire [63:0] y_div;

	//mul
	wire mul_sign,mul_valid;
	assign mul_sign = (alucontrolE == `MULT_CONTROL);
	assign mul_valid = (alucontrolE == `MULT_CONTROL || alucontrolE == `MULTU_CONTROL);
	wire [63:0] y_mul;




	//final logic
	assign hilo_out = ({64{div_valid}} & y_div) | ({64{mul_valid}} & y_mul) 		//乘除法
				| ({64{~div_valid & ~mul_valid}} & {32'b0,result})					//非乘除法
				| ({64{(alucontrolE == `MTHI_CONTROL)}} & {a,hilo_in[31:0]})
				| ({64{(alucontrolE == `MTLO_CONTROL)}} & {hilo_in[63:32],a}); 		

	// todo：改进hilo的写逻辑
	reg div_start;

	always @(*) begin
		if (alucontrolE == `DIV_CONTROL || alucontrolE == `DIVU_CONTROL) begin
			if(div_ready == 1'b0) begin
				div_start = 1'b1;
			end
			else if(div_ready == 1'b1) begin
				div_start = 1'b0;
			end
			else begin
				div_start = 1'b0;
			end	
		end
		else begin
			div_start = 1'b0;
		end
	end


	wire mul_ready;
	reg mul_start;

	always @(*) begin
		if(alucontrolE == `MULT_CONTROL || alucontrolE == `MULTU_CONTROL) begin
			if(mul_ready == 1'b0) begin
				mul_start = 1'b1;
			end
			else if(mul_ready == 1'b1) begin
				mul_start = 1'b0;
			end
			else begin
				mul_start = 1'b0;
			end
		end
		else begin
			mul_start = 1'b0;
		end
	end

	//接入除法器
	wire tempDiv_stall;
	assign div_stall = tempDiv_stall & ~is_except;
	//todo: annual 信号
	div div(clk,rst,div_sign,a,b,div_start,1'b0,y_div,div_ready,tempDiv_stall);

	//接入乘法器
	wire tempMul_stall;
	assign mul_stall = tempMul_stall & ~is_except;
	mul mul(clk,rst,mul_sign,a,b,mul_start,y_mul,mul_ready,tempMul_stall);

	
	always @(*) begin
		case(alucontrolE)
			//逻辑运算8条
			`AND_CONTROL   :  result = a & b;  //指令AND、ANDI
			`OR_CONTROL    :  result = a | b;  //指令OR、ORI
			`XOR_CONTROL   :  result = a ^ b;  //指令XOR
			`NOR_CONTROL   :  result = ~(a | b);  //指令NOR、XORI
			`LUI_CONTROL   :  result = {b[15:0],16'b0}; //指令LUI
			//移位指令6条
			`SLL_CONTROL   :  result = b << sa;  //指令SLL
			`SRL_CONTROL   :  result = b >> sa;  //指令SRL
			`SRA_CONTROL   :  result = $signed(b) >>> sa;  //指令SRL
			`SLLV_CONTROL  :  result = b << a[4:0];  //指令SLLV
			`SRLV_CONTROL  :  result = b >> a[4:0];  //指令SRLV
			`SRAV_CONTROL  :  result = $signed(b) >>> a[4:0]; //指令SRAV
			//算数运算指令14条
			`ADD_CONTROL   :  {double_sign,result} = {a[31],a} + {b[31],b}; //指令ADD、ADDI
			`ADDU_CONTROL  :  result = a + b; //指令ADDU、ADDIU
			`SUB_CONTROL   :  {double_sign,result} = {a[31],a} - {b[31],b}; //指令SUB
			`SUBU_CONTROL  :  result = a - b; //指令SUBU
			`SLT_CONTROL   :  result = $signed(a) < $signed(b) ? 32'b1 : 32'b0;  //指令SLT、SLTI
			`SLTU_CONTROL  :  result = a < b ? 32'b1 : 32'b0; //指令SLTU、SLTIU
			// `MULT_CONTROL  :  hilo_out = $signed(a) * $signed(b); //指令MULT 
			// `MULTU_CONTROL :  hilo_out = {32'b0, a} * {32'b0, b}; //指令MULTU
			// `DIV_CONTROL   :  begin //指令DIV, 除法器控制状态机逻辑
			// 	if(~div_ready & ~div_start) begin //~div_start : 为了保证除法进行过程中，除法源操作数不因ALU输入改变而重新被赋值
			// 		//必须非阻塞赋值，否则时序不对
			// 		div_start <= 1'b1;
			// 		div_signed <= 1'b1;
			// 		div_stall <= 1'b1;
			// 		a_save <= a; //除法时保存两个操作数
			// 		b_save <= b;
			// 	end
			// 	else if(div_ready) begin
			// 		div_start <= 1'b0;
			// 		div_signed <= 1'b1;
			// 		div_stall <= 1'b0;
			// 		hilo_out <= div_result;
			// 	end
			// end
			// `DIVU_CONTROL  :  begin //指令DIVU, 除法器控制状态机逻辑
			// 	if(~div_ready & ~div_start) begin //~div_start : 为了保证除法进行过程中，除法源操作数不因ALU输入改变而重新被赋值
			// 		//必须非阻塞赋值，否则时序不对
			// 		div_start <= 1'b1;
			// 		div_signed <= 1'b0;
			// 		div_stall <= 1'b1;
			// 		a_save <= a; ////除法时保存两个操作数
			// 		b_save <= b;
			// 	end
			// 	else if(div_ready) begin
			// 		div_start <= 1'b0;
			// 		div_signed <= 1'b0;
			// 		div_stall <= 1'b0;
			// 		hilo_out <= div_result;
			// 	end
			// end
			//数据移动指令4条
			// `MFHI_CONTROL  :  result = hilo_in[63:32]; //指令MFHI
			// `MFLO_CONTROL  :  result = hilo_in[31:0]; //指令MFLO
			// `MTHI_CONTROL  :  hilo_out = {a,hilo_in[31:0]}; //指令MTHI
			// `MTLO_CONTROL  :  hilo_out = {hilo_in[63:32],a}; //指令MTLO
			default        :  result = `ZeroWord;
		endcase
	end

	// wire annul; //终止除法信号
	// assign annul = ((alucontrolE == `DIV_CONTROL)|(alucontrolE == `DIVU_CONTROL)) & is_except;



endmodule