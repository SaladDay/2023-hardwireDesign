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
	output wire flushF,
	input wire instrStall,
	//decode stage
	input wire[4:0] rsD,rtD,
	input wire branchD,
	input wire jrD,
	output wire forwardaD,forwardbD,
	output wire stallD,
	output wire flushD,
	//execute stage
	input wire[4:0] rsE,rtE,rdE,
	input wire[4:0] writeregE,
	input wire regwriteE,
	input wire memtoregE,
	input wire div_stallE,
	input wire mul_stallE,
	input wire hilotoregE,
	input wire cp0toregE,

	output reg[1:0] forwardaE,forwardbE,
	
	output wire stallE,
	output wire flushE,
	//mem stage
	input wire dataStall,
	input wire[4:0] writeregM,
	input wire regwriteM,
	input wire memtoregM,
	input wire is_exceptM,
	output wire stallM,
	output wire flushM,

	//write back stage
	input wire[4:0] writeregW,
	input wire regwriteW,
	output wire stallW,
	output wire flushW,

	output wire longest_stall
    );

	wire lwstallD,branchstallD,jrstallD,hilostallD;

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


	//------------------stall judge start------------------//
	//stalls
	//lwstallD:对正处于execute阶段的指令进行检查，如果发现是lw指令，并且他的目的寄存器rtE，与
	//		  当前正处于Decode阶段的指令的任一源寄存器相同，则进入lwstall。
	//		  通过flushE，在execute阶段插入一个气泡
	assign lwstallD = memtoregE & (rtE == rsD | rtE == rtD);
	//branchstallD:
	//				当检测到Decode阶段为branch指令时：
	//				1. 如果Writeback阶段的指令将新值写入reg，则不会发送冒险
	//				2. 如果在memory阶段的指令产生了写入寄存器的新值，分为两种情况：
	//				2.1 在memmory阶段的不是lw指令，则在lw的前半拍就出结果，用旁路即可
	//				2.2 如果为lw指令，则位于decode阶段的beq就必须等待一个周期stallF，stallD，flushE
	//				3. 如果在execute阶段的指令产生了写入寄存器的新值，也需要等待一周期如上
	//
	assign branchstallD = branchD &
				(regwriteE & 
				(writeregE == rsD | writeregE == rtD) |
				memtoregM &
				(writeregM == rsD | writeregM == rtD));

	assign hilostallD = hilotoregE & (rdE == rsD | rdE == rtD);

	assign cp0stallD = cp0toregE & (rtE == rsD | rtE == rtD);

	assign jrstallD = jrD &
			(regwriteE & 
			(writeregE == rsD | writeregE == rtD) |
			memtoregM &
			(writeregM == rsD | writeregM == rtD));


	wire other_stall;
	assign other_stall = (lwstallD | branchstallD | jrstallD | cp0stallD | hilostallD) & ~is_exceptM;
	assign longest_stall = instrStall | dataStall | div_stallE | mul_stallE;
	//------------------stall judge end------------------//




	//------------------stall decode start------------------//
	// assign stallD = longest_stall | hilostallD | lwstallD | branchD | cp0stallD | jrstallD;
	// assign stallF = (~is_exceptM & stallD); 
	// assign stallE = longest_stall; //执行除法时EX阶段暂停
	// assign stallM = longest_stall;
	// assign stallW = longest_stall & ~is_exceptM;

	assign stallF = longest_stall | other_stall;
	assign stallD = longest_stall | other_stall;
	assign stallE = longest_stall;
	assign stallM = longest_stall;
	assign stallW = longest_stall;
	//------------------stall decode end------------------//

	//------------------flush decode start------------------//
	// assign flushF = is_exceptM;
	// assign flushD = is_exceptM;
	// assign flushE = (( ) & ~longest_stall) | is_exceptM; //stalling D flushes next stage
	// assign flushM = is_exceptM;
	// assign flushW = is_exceptM;
	assign flushF = is_exceptM;
	assign flushD = is_exceptM;
	assign flushE = other_stall & ~longest_stall | is_exceptM;
	assign flushM = is_exceptM;
	assign flushW = is_exceptM;
	//------------------flush decode end------------------//
endmodule

















