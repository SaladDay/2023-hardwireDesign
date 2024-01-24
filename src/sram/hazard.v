`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/11/22 10:23:13
// Design Name: 
// Module Name: hazard
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


module hazard(
	//fetch stage
	output wire stallF,
	//decode stage
	input wire[4:0] rsD,rtD,
	input wire branchD,
	input wire jrD,
	output wire forwardaD,forwardbD,
	output wire stallD,
	//execute stage
	input wire[4:0] rsE,rtE,
	input wire[4:0] writeregE,
	input wire regwriteE,
	input wire memtoregE,
	input wire div_stallE,
	output reg[1:0] forwardaE,forwardbE,
	output wire flushD,
	output wire flushE,
	output wire flushM,
	output wire flushW,
	output wire stallE,
	//mem stage
	input wire[4:0] writeregM,
	input wire regwriteM,
	input wire memtoregM,
	input wire is_exceptM,

	//write back stage
	input wire[4:0] writeregW,
	input wire regwriteW
    );

	wire lwstallD,branchstallD;

	//forwarding to D (branch equality)
	assign forwardaD = (rsD != 0 & rsD == writeregM & regwriteM);
	assign forwardbD = (rtD != 0 & rtD == writeregM & regwriteM);
	
	//forwarding to E (ALU)
	//10 from M
	//01 from W
	always @(*) begin
		forwardaE = 2'b00;
		forwardbE = 2'b00;
		if(rsE != 0) begin
			/* code */
			if(rsE == writeregM & regwriteM) begin
				/* code */
				forwardaE = 2'b10;
			end else if(rsE == writeregW & regwriteW) begin
				/* code */
				forwardaE = 2'b01;
			end
		end
		if(rtE != 0) begin
			/* code */
			if(rtE == writeregM & regwriteM) begin
				/* code */
				forwardbE = 2'b10;
			end else if(rtE == writeregW & regwriteW) begin
				/* code */
				forwardbE = 2'b01;
			end
		end
	end

	//stalls
	//lwstallD:对正处于execute阶段的指令进行检查，如果发现是lw指令，并且他的目的寄存器rtE，与
	//		  当前正处于Decode阶段的指令的任一源寄存器相同，则进入lwstall。
	//		  通过flushE，在execute阶段插入一个气泡
	assign lwstallD = memtoregE & (rtE == rsD | rtE == rtD);
	//branchstallD:
	//				当检测到Decode阶段为branch指令时：
	//				1. 如果Writeback阶段的前序指令将新值写入reg，则不会发送冒险
	//				2. 如果在memory阶段的前序指令产生了写入寄存器的新值，分为两种情况：
	//				2.1 在memmory阶段的不是lw指令，则在lw的前半拍就出结果，用旁路即可
	//				2.2 如果为lw指令，则位于decode阶段的beq就必须等待一个周期stallF，stallD，flushE
	//				3. 如果在execute阶段的前序指令产生了写入寄存器的新值，也需要等待一周期如上
	//
	assign branchstallD = (branchD | jrD) &
				(regwriteE & (writeregE == rsD | writeregE == rtD) |
				memtoregM & (writeregM == rsD | writeregM == rtD));



	assign stallD = lwstallD | branchstallD | div_stallE;
	//触发异常处理时，可能有后续指令(无效执行指令)会暂停流水线，
	//这个暂停会导致pc取不到异常处理地址0xBFC00380。因为暂停时，pc保持不变，
	//然后下一周期不暂停了，但是0xBFC00380也流走了，所以这个异常就得不到处理，出错
	//因此，触发异常时，不能暂停取指阶段 
	assign stallF = (~is_exceptM & (lwstallD | branchstallD | div_stallE)); 
	assign stallE = div_stallE; //执行除法时EX阶段暂停
	
	assign flushD = is_exceptM;
	assign flushE = lwstallD | branchstallD | is_exceptM; //stalling D flushes next stage
	assign flushM = is_exceptM | div_stallE;
	assign flushW = is_exceptM;
endmodule
