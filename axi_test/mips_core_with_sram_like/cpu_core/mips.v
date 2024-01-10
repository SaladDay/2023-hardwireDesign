`timescale 1ns / 1ps
`include "defines2.vh"

module mips(
	input wire clk,rst,
	input wire [5:0] ext_int,//硬件中断标识
	//instr
	output wire[31:0] pcF,
	input wire[31:0] instrF,
	output wire instr_enF, 
	input wire instrStall,


	//read data
	input wire dataStall,
	output wire[31:0] aluoutM,
	input wire[31:0] readdataM,
	//write data
	output wire[31:0] mem_write_dataM,
	output wire mem_enM, //存储器使能
	output wire [3:0] mem_wenM,

	output wire longest_stall,
	//for debug
    output [31:0] debug_wb_pc     ,
    output [3:0] debug_wb_rf_wen  ,
    output [4:0] debug_wb_rf_wnum ,
    output [31:0] debug_wb_rf_wdata
    );

	wire [31:0] instrD;
	wire [4:0] alucontrolD;
	wire [1:0] regdstD;
	wire memtoregD,memwriteD,branchD,
		alusrcD,regwriteD,jumpD,
		hilo_writeD,jbralD,jrD,
		cp0_writeD,is_invalidD,
		hilotoregD,cp0toregD,
		memreadD;
	wire [1:0] mfhi_loD;

	datapath datapath(
		clk,rst,ext_int,instrD,
		alucontrolD,memtoregD,memwriteD,branchD,
		alusrcD,regwriteD,jumpD,
		hilo_writeD,jbralD,jrD,
		cp0_writeD,is_invalidD,
		regdstD,hilotoregD,cp0toregD,memreadD,mfhi_loD,
		
		instrStall,
		dataStall,
		pcF,
		instrF,
		instr_enF,
		aluoutM,mem_write_dataM,
		readdataM,
		mem_enM,
		mem_wenM,
		longest_stall,
		debug_wb_pc,
		debug_wb_rf_wen,
		debug_wb_rf_wnum,
		debug_wb_rf_wdata

	);

	controller controller(
		instrD,
		alucontrolD,
		memtoregD,
		memwriteD,
		branchD,
		alusrcD,
		regwriteD,
		jumpD,
		hilo_writeD,
		jbralD,
		jrD,
		cp0_writeD,
		is_invalidD,
		hilotoregD,
		cp0toregD,
		regdstD,
		memreadD,
		mfhi_loD
	);

	
endmodule
