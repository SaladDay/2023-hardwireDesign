module mycpu_top(
    input clk,
    input resetn,  //low active
    input [5:0] ext_int,
    //cpu inst sram
    output        inst_sram_en   ,
    output [3 :0] inst_sram_wen  ,
    output [31:0] inst_sram_addr ,
    output [31:0] inst_sram_wdata,
    input  [31:0] inst_sram_rdata,
    //cpu data sram
    output        data_sram_en   ,
    output [3 :0] data_sram_wen  ,
    output [31:0] data_sram_addr ,
    output [31:0] data_sram_wdata,
    input  [31:0] data_sram_rdata, 
    //for debug
    output [31:0] debug_wb_pc     ,
    output [3:0] debug_wb_rf_wen  ,
    output [4:0] debug_wb_rf_wnum ,
    output [31:0] debug_wb_rf_wdata
);

	wire [31:0] pc;
	wire [31:0] instr;
    wire data_en;
	wire [31:0] aluout, writedata, readdata;
	wire [3:0] mem_wen;
	
	//for mmu
	wire [31:0] inst_vaddr;
	wire [31:0] inst_paddr;
	wire [31:0] data_vaddr;
	wire [31:0] data_paddr;
	
    mips mips(
        .clk(~clk),//时钟取反，这样DRAM和IRAM可以在同一时钟周期取值
        .rst(~resetn),
        .ext_int(ext_int),
        //instr
        // .inst_en(inst_en),
        .pcF(pc),                    //pcF
        .instrF(instr),              //instrF
        //data
        .mem_enM(data_en),
        .aluoutM(aluout),
        .mem_write_dataM(writedata),
        .readdataM(readdata),
        .mem_wenM(mem_wen),
        //for debug
        .debug_wb_pc       (debug_wb_pc       ),  
        .debug_wb_rf_wen   (debug_wb_rf_wen   ),  
        .debug_wb_rf_wnum  (debug_wb_rf_wnum  ),  
        .debug_wb_rf_wdata (debug_wb_rf_wdata )
    );
    
    assign inst_vaddr = pc;
    assign data_vaddr = aluout;
    mmu mmu(
        .inst_vaddr(inst_vaddr),
        .inst_paddr(inst_paddr),
        .data_vaddr(data_vaddr),
        .data_paddr(data_paddr)
    );

    assign inst_sram_en = 1'b1;     //如果有inst_en，就用inst_en
    assign inst_sram_wen = 4'b0;
    assign inst_sram_addr = inst_paddr;
    assign inst_sram_wdata = 32'b0;
    assign instr = inst_sram_rdata;

    assign data_sram_en = data_en;     //如果有data_en，就用data_en
    assign data_sram_wen = mem_wen;
    assign data_sram_addr = data_paddr;
    assign data_sram_wdata = writedata;
    assign readdata = data_sram_rdata;
    

    //ascii
    instdec instdec(
        .instr(instr)
    );

endmodule