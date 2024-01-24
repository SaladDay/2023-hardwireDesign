`include "defines2.vh"
`timescale 1ns / 1ps

module datapath(
    input wire clk,rst,
	input wire [5:0] ext_int,	//硬件中断标识
	//controller
    output wire [31:0] instrD,
    input wire[4:0] alucontrolD,
    input wire memtoregD,
		memwriteD,branchD,
		alusrcD,regwriteD,jumpD,
		hilo_writeD,jbralD,jrD,
		cp0_writeD,is_invalidD,
	input wire[1:0] regdstD,
	input wire hilotoregD,cp0toregD,memreadD,
	input wire [1:0] mfhi_loD,

	//mips
	input wire instrStall,
	input wire dataStall,
	output wire[31:0] pcF,
	input wire[31:0] instrF,
	output wire instr_enF,
	output wire[31:0] aluoutM,mem_write_dataM,
	input wire[31:0] readdataM,
	output wire mem_enM, //存储器使能
	output wire [3:0] mem_wenM,
	
	output wire longest_stall,
	//for debug
    output [31:0] debug_wb_pc     ,
    output [3:0] debug_wb_rf_wen  ,
    output [4:0] debug_wb_rf_wnum ,
    output [31:0] debug_wb_rf_wdata
);
	//----------------------------------------------internal signal----------------------------------------------------	
    // PC
	wire [31:0] pcplus4F,
				pcbranchD,
				pc4branchFD,
				pc4branchjFD,
				pc4branchjjrFD,
				pcnextFD;

	//F datapath
	wire stallF,flushF;
	wire is_AdEL_pcF;
	wire is_in_delayslotF; //当前指令是否在延迟槽

	//D controler
	wire pcsrcD;//计算是否要分支
	wire equalD;
	//D datapath
	wire [31:0] pcplus4D;
	wire forwardaD,forwardbD;
	wire [5:0] opD,functD;
	wire [4:0] rsD,rtD,rdD,saD;
	wire stallD,flushD; //D阶段刷新，暂停信号
	wire [31:0] signimmD,signimmshD;
	wire [31:0] srcaD,srca2D,srcbD,srcb2D;
	wire is_AdEL_pcD,is_syscallD,is_breakD,is_eretD; //例外标记
	wire is_in_delayslotD; 
	wire [31:0] pcD;
	wire [4:0] cp0_waddrD; //cp0写地址，指令MTC0
	wire [4:0] cp0_raddrD; //cp0读地址，指令MFC0
	

	//E controler
	wire regwriteE,alusrcE,memwriteE,memtoregE,memreadE;
	wire [1:0] regdstE;
	wire [4:0] alucontrolE;
	wire hilo_writeE; //hilo寄存器写信号
	wire is_invalidE;
	wire jbralE,cp0_writeE;		
	wire [1:0] mfhi_loE;
	//E datapath
	wire [1:0] forwardaE,forwardbE;
	wire hilotoregE,cp0toregE;
	wire [5:0] opE;
	wire [4:0] rsE,rtE,rdE,saE;
	wire [4:0] writeregE;
	wire [31:0] signimmE;
	wire [31:0] srcaE,srca2E,srca3E,  srcbE,srcb2E,srcb3E,srcb4E;
	wire [31:0] aluoutE;
	wire [63:0] read_hiloM,All_aluoutE;//HILO读写数据

	wire div_stallE; //除法导致的流水线暂停控制
	wire mul_stallE; //乘法流水线暂停
	wire stallE,flushE; //Ex阶段暂停、刷新控制信号
	wire is_AdEL_pcE,is_syscallE,is_breakE,is_eretE,is_overflowE; //例外标记
	wire is_in_delayslotE;
	wire [31:0] pcE;
	wire [4:0] cp0_waddrE;
	wire [4:0] cp0_raddrE;
	wire [31:0] cp0_rdataE,cp0_rdata2E; //shan
	wire [31:0] cp0_rdataM;


	//M controller
	wire regwriteM,memtoregM,memwriteM,memreadM;
	wire hilotoregM;
	wire cp0toregM;
	wire is_invalidM; //保留指令	
	wire cp0_writeM; //cp0寄存器写信号
	wire hilo_writeM;
	wire [1:0] mfhi_loM;
	//M datapath
	wire [5:0] opM;
	wire [4:0] writeregM;
	wire [31:0] final_read_dataM,writedataM;
	wire flushM,stallM;
	wire is_AdEL_pcM,is_syscallM,is_breakM,is_eretM,is_AdEL_dataM,is_AdES_dataM,is_overflowM; //例外标记
	wire is_in_delayslotM;
	wire [31:0] pcM;
	wire [4:0] cp0_waddrM;
	wire is_exceptM;
	wire [31:0] except_typeM;
	wire [31:0] except_pcM;
	wire [31:0] cp0_countM,cp0_compareM,cp0_statusM,cp0_causeM,
				cp0_epcM,cp0_configM,cp0_pridM,cp0_badvaddrM;
	wire cp0_timer_intM;
	wire [31:0] bad_addrM;
	wire [31:0] resultM;
	wire [63:0] aluoutHiloM;

	//W controller
	wire regwriteW,memtoregW;
	//W datapath
	wire [4:0] writeregW;
	wire [31:0] aluoutW,readdataW,resultW;
	wire flushW,stallW;

	
	
//----------------------------------------------for debug begin----------------------------------------------------	
    wire [31:0] pcW;
    wire [31:0] instrE,instrM;
    flopenrc #(32) rinstrE(clk,rst,~stallE,flushE,instrD,instrE);
    flopenrc #(32) rinstrM(clk,rst,~stallM,flushM,instrE,instrM);

    flopenrc #(32) rpcW(clk,rst,~stallW,flushW,pcM,pcW);
    assign debug_wb_pc          = pcW;
    assign debug_wb_rf_wen      = {4{regwriteW & ~stallW}};
    assign debug_wb_rf_wnum     = writeregW;
    assign debug_wb_rf_wdata    = resultW;
//----------------------------------------------for debug end----------------------------------------------------

//----------------------------------------controler pipeline------------------------------------------

	assign pcsrcD = branchD & equalD;
	flopenrc #(20) regE(
		clk,
		rst,
		~stallE,
		flushE,
		{memtoregD,memwriteD,alusrcD,regdstD,regwriteD,alucontrolD,hilo_writeD,jbralD,cp0_writeD,is_invalidD,hilotoregD,cp0toregD,memreadD,mfhi_loD},
		{memtoregE,memwriteE,alusrcE,regdstE,regwriteE,alucontrolE,hilo_writeE,jbralE,cp0_writeE,is_invalidE,hilotoregE,cp0toregE,memreadE,mfhi_loE}
		);
	flopenrc #(12) regM(
		clk,
		rst,
		~stallM,
		flushM,
		{memtoregE,memwriteE,regwriteE,cp0_writeE,is_invalidE,memreadE,cp0toregE,hilo_writeE,mfhi_loE,hilotoregE},
		{memtoregM,memwriteM,regwriteM,cp0_writeM,is_invalidM,memreadM,cp0toregM,hilo_writeM,mfhi_loM,hilotoregM}
		);
	flopenrc #(2) regW(
		clk,
		rst,
		~stallW,
		flushW,
		{memtoregM,regwriteM},
		{memtoregW,regwriteW}
		);
//----------------------------------------controler pipeline end------------------------------------------

//----------------------------------------datapath logic------------------------------------------

	hazard h(
		//fetch stage
		stallF,
		flushF,//几乎没用
		instrStall,
		//decode stage
		rsD,rtD,
		branchD,
		jrD,
		forwardaD,forwardbD,
		stallD,
		flushD,
		//execute stage
		rsE,rtE,rdE,
		writeregE,
		regwriteE,
		memtoregE,
		div_stallE,
		mul_stallE,

		hilotoregE,
		cp0toregE,

		forwardaE,forwardbE,
		stallE,
		flushE,
		//mem stage
		dataStall,
		writeregM,
		regwriteM,
		memtoregM,
		is_exceptM,
		stallM,
		flushM,
		//write back stage
		writeregW,
		regwriteW,
		stallW,
		flushW,
		longest_stall

		);

	//next PC logic (operates in fetch an decode)
	mux2 #(32) pcbrmux(pcplus4F,pcbranchD,pcsrcD,pc4branchFD);
	mux2 #(32) pcjumpmux(pc4branchFD,
		{pcplus4D[31:28],instrD[25:0],2'b00},
		jumpD,pc4branchjFD);
	mux2 #(32) pc_jr_mux(pc4branchjFD,srca2D,jrD,pc4branchjjrFD);
	mux2 #(32) pc_except_mux(pc4branchjjrFD,except_pcM,is_exceptM,pcnextFD); //处理异常添加

	//regfile (operates in decode and writeback)
	regfile rf(clk,regwriteW,rsD,rtD,writeregW,resultW,srcaD,srcbD);

	//fetch stage logic
	pc #(32) pcreg(clk,rst,~stallF,pcnextFD,pcF);
	adder pcadd1(pcF,32'b100,pcplus4F);

	assign instr_enF =  ~is_exceptM & ~is_AdEL_pcF;
	assign is_AdEL_pcF = ~(pcF[1:0] == 2'b00);
	assign is_in_delayslotF = jumpD | branchD | jbralD | jrD;

	//decode stage
	flopenrc #(32) r1D(clk,rst,~stallD,flushD,pcplus4F,pcplus4D);
	flopenrc #(32) r2D(clk,rst,~stallD,flushD,instrF,instrD);
	flopenrc #(1) r3D(clk,rssrcb2Dt,~stallD,flushD,is_AdEL_pcF,is_AdEL_pcD);
	flopenrc #(1) r4D(clk,rst,~stallD,flushD,is_in_delayslotF,is_in_delayslotD);
	flopenrc #(32) r5D(clk,rst,~stallD,flushD,pcF,pcD);

	signext se(instrD[15:0],opD[3:2],signimmD);
	sl2 immsh(signimmD,signimmshD);
	adder pcadd2(pcplus4D,signimmshD,pcbranchD);

	wire [31:0] toForwardM;
	assign toForwardM = resultM;

	mux2 #(32) forwardamux(srcaD,toForwardM,forwardaD,srca2D);
	mux2 #(32) forwardbmux(srcbD,toForwardM,forwardbD,srcb2D);
	eqcmp comp(srca2D,srcb2D,opD,rtD,equalD);

	assign opD = instrD[31:26];
	assign functD = instrD[5:0];
	assign rsD = instrD[25:21];
	assign rtD = instrD[20:16];
	assign rdD = instrD[15:11];
	assign saD = instrD[10:6];

	assign is_breakD = (opD == 6'b000000) & (functD == `BREAK);
	assign is_syscallD = (opD == 6'b000000) & (functD == `SYSCALL);
	assign is_eretD = (instrD == 32'b01000010000000000000000000011000);
	assign cp0_waddrD = rdD;
	assign cp0_raddrD = rdD;

	//execute stage
	flopenrc #(32) r1E(clk,rst,~stallE,flushE,srcaD,srcaE);
	flopenrc #(32) r2E(clk,rst,~stallE,flushE,srcbD,srcbE);
	flopenrc #(32) r3E(clk,rst,~stallE,flushE,signimmD,signimmE);
	flopenrc #(5) r4E(clk,rst,~stallE,flushE,rsD,rsE);
	flopenrc #(5) r5E(clk,rst,~stallE,flushE,rtD,rtE);
	flopenrc #(5) r6E(clk,rst,~stallE,flushE,rdD,rdE);
	flopenrc #(5) r7E(clk,rst,~stallE,flushE,saD,saE);
	flopenrc #(6) r8E(clk,rst,~stallE,flushE,opD,opE);
	flopenrc #(4) r9E(clk,rst,~stallE,flushE,
		{is_AdEL_pcD,is_syscallD,is_breakD,is_eretD},
		{is_AdEL_pcE,is_syscallE,is_breakE,is_eretE});
	flopenrc #(1) r10E(clk,rst,~stallE,flushE,is_in_delayslotD,is_in_delayslotE);
	flopenrc #(32) r11E(clk,rst,~stallE,flushE,pcD,pcE);
	flopenrc #(5) r12E(clk,rst,~stallE,flushE,cp0_waddrD,cp0_waddrE);
	flopenrc #(5) r13E(clk,rst,~stallE,flushE,cp0_raddrD,cp0_raddrE);
	


	mux3 #(32) forwardaemux(srcaE,resultW,toForwardM,forwardaE,srca2E);
	mux3 #(32) forwardbemux(srcbE,resultW,toForwardM,forwardbE,srcb2E);
	mux2 #(32) srcbmux(srcb2E,signimmE,alusrcE,srcb3E);
	//跳转链接类指令,复用ALU,ALU源操作数选择分别为pcE and 8
	mux2 #(32) alusrcamux(srca2E,pcE,jbralE,srca3E);
	mux2 #(32) alusrcbmux(srcb3E,32'h00000008,jbralE,srcb4E);
	
	//CP0写后读数据前推
	mux2 #(32) forwardcp0mux(cp0_rdataE,aluoutM,(cp0_raddrE == cp0_waddrM),cp0_rdata2E); 

	alu alu(clk,rst,srca3E,srcb4E,alucontrolE,saE,read_hiloM,cp0_rdata2E,is_exceptM,
			All_aluoutE,mul_stallE,div_stallE,is_overflowE);
	assign aluoutE = All_aluoutE[31:0];
	mux3 #(5) wrmux(rtE,rdE,5'd31,regdstE,writeregE);

	//mem stage
	flopenrc #(32) r1M(clk,rst,~stallM,flushM,srcb2E,writedataM);
	flopenrc #(32) r2M(clk,rst,~stallM,flushM,aluoutE,aluoutM);
	flopenrc #(5) r3M(clk,rst,~stallM,flushM,writeregE,writeregM);
	flopenrc #(6) r4M(clk,rst,~stallM,flushM,opE,opM);
	flopenrc #(5) r5M(clk,rst,~stallM,flushM,
		{is_AdEL_pcE,is_syscallE,is_breakE,is_eretE,is_overflowE},
		{is_AdEL_pcM,is_syscallM,is_breakM,is_eretM,is_overflowM});
	flopenrc #(1) r6M(clk,rst,~stallM,flushM,is_in_delayslotE,is_in_delayslotM);
	flopenrc #(32) r7M(clk,rst,~stallM,flushM,pcE,pcM);
	flopenrc #(5) r8M(clk,rst,~stallM,flushM,cp0_waddrE,cp0_waddrM);
	flopenrc #(64) r9M(clk,rst,~stallM,flushM,All_aluoutE,aluoutHiloM);



	hilo_reg hilo_reg(
		.clk(clk),
		.rst(rst),
		.we(hilo_writeM),		//todo :检查是否需要异常处理
		.hilo_in(aluoutHiloM),
		.hilo_out(read_hiloM)
	);
	wire [31:0] hiloresultM;
	mux2 #(32) hilomux(read_hiloM[63:32],read_hiloM[31:0],mfhi_loM[0],hiloresultM);//mfhilo 取结果

	assign mem_enM = (memreadM | memwriteM) & ~is_exceptM; //存储器使能，防止异常地址写入或读出
	mem_ctrl mem_ctrl(opM,aluoutM,readdataM,final_read_dataM,writedataM,mem_write_dataM,mem_wenM,is_AdEL_dataM,is_AdES_dataM);
	exceptdec exceptdec(
		//input
		.clk(clk),              
		.rst(rst),              
		.ext_int(ext_int),   
		.cp0_status(cp0_statusM),  
		.cp0_cause(cp0_causeM),  
		.cp0_epc(cp0_epcM),    
		.is_syscallM(is_syscallM),      
		.is_breakM(is_breakM),        
		.is_eretM(is_eretM),         
		.is_AdEL_pcM(is_AdEL_pcM),      
		.is_AdEL_dataM(is_AdEL_dataM),    
		.is_AdES_dataM(is_AdES_dataM),         
		.is_overflowM(is_overflowM),     
		.is_invalidM(is_invalidM),   
		//output   
		.is_except(is_exceptM),       
		.except_type(except_typeM),
		.except_pc(except_pcM)   
	);
	assign bad_addrM = is_AdEL_pcM ? pcM : aluoutM;
	wire [31:0] current_inst_addr;
	flopr #(32) except_inst_addr(clk,rst,pcE,current_inst_addr); //写入cp0_epc, 由 pcE 传递来，无flush
	cp0_reg cp0_reg(
		//input
		.clk(clk),                          
		.rst(rst),
		.we_i(cp0_writeM & ~stallM),    
		.waddr_i(instrM[15:11]),
		.raddr_i(instrM[15:11]),
		.data_i(writedataM),  //gai chegn writedataM
		.int_i(ext_int),
		.excepttype_i(except_typeM),
		.current_inst_addr_i(pcM),  //改成pcM
		.is_in_delayslot_i(is_in_delayslotM),
		.bad_addr_i(bad_addrM),
		//output
		.data_o(cp0_rdataM),
		.count_o(cp0_countM),
		.compare_o(cp0_compareM),
		.status_o(cp0_statusM), //用于判断中断
		.cause_o(cp0_causeM), //用于判断中断
		.epc_o(cp0_epcM),  //用于ERET
		.config_o(cp0_configM),
		.prid_o(cp0_pridM),
		.badvaddr(cp0_badvaddrM),
		.timer_int_o(cp0_timer_intM)
	);

	wire [31:0] resultaM,resultbM;
	mux2 #(32) res1mux(aluoutM,final_read_dataM,memtoregM,resultaM);
	mux2 #(32) res2mux(resultaM,cp0_rdataM,cp0toregM,resultbM);
	mux2 #(32) res3mux(resultbM,hiloresultM,hilotoregM,resultM);


	//writeback stage
	flopenrc #(32) r1W(clk,rst,~stallW,flushW,aluoutM,aluoutW);
	flopenrc #(32) r2W(clk,rst,~stallW,flushW,final_read_dataM,readdataW);
	flopenrc #(5) r3W(clk,rst,~stallW,flushW,writeregM,writeregW);
	flopenrc #(32) r4W(clk,rst,~stallW,flushW,resultM,resultW);

//----------------------------------------datapath 模块end------------------------------------------

endmodule