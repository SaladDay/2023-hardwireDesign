/*
//           --------------------------------------- -----------------------   mycpu_top.v
//        |   -------------------------    mips core with sram_like         |
//        |   |        mips_core       |                                    |
//        |   -------------------------                                     |
//        |        | sram         | sram                                    |
//        |      ----           ----                                        |
//        |     |    |         |    |                                       |
//        |      ----           ----                                        |
//        |        | sram-like    | sram-like                               |
//           ---------------------------------------------------------------
//                 | sram-like    | sram-like
//           ---------------------------------------
//        |    				MMU                      |
//        |    								         |
//           ---------------------------------------
//                 | sram-like    | sram-like

*/

module mycpu_top(

    input [5:0] ext_int,

    input wire aclk,                //axi clk  
    input wire aresetn,             //axi reset,active low
    
    //address read
    output wire[3:0] arid,
    output wire[31:0] araddr,
    output wire[7:0] arlen,
    output wire[2:0] arsize,
    output wire[1:0] arburst,
    output wire[1:0] arlock,
    output wire[3:0] arcache,
    output wire[2:0] arprot,
    output wire arvalid,
    input wire arready,
    
    //read
    input wire[3:0] rid,
    input wire[31:0] rdata,
    input wire[1:0] rresp,
    input wire rlast,
    input wire rvalid,
    output wire rready,
    
    //address write
    output wire[3:0] awid,
    output wire[31:0] awaddr,
    output wire[7:0] awlen,
    output wire[2:0] awsize,
    output wire[1:0] awburst,
    output wire[1:0] awlock,
    output wire[3:0] awcache,
    output wire[2:0] awprot,
    output wire awvalid,
    input wire awready,


    //write
    output wire[3:0] wid,
    output wire[31:0] wdata,
    output wire[3:0] wstrb,
    output wire wlast,
    output wire wvalid,
    input wire wready,
    
    //写响应通道
    input wire[3:0] bid,
    input wire[1:0] bresp,
    input bvalid,
    output bready,





    //debug
    output wire[31:0] debug_wb_pc,
    output wire[3:0] debug_wb_rf_wen,
    output wire[4:0] debug_wb_rf_wnum,
    output wire[31:0] debug_wb_rf_wdata
);
wire clk, rst;
assign clk = aclk;
assign rst = ~aresetn;


wire        cpu_inst_req  ;
wire [31:0] cpu_inst_addr ;
wire        cpu_inst_wr   ;
wire [1:0]  cpu_inst_size ;
wire [31:0] cpu_inst_wdata;
wire [31:0] cpu_inst_rdata;
wire        cpu_inst_addr_ok;
wire        cpu_inst_data_ok;



wire        cpu_data_req  ;
wire [31:0] cpu_data_addr ;
wire        cpu_data_wr   ;
wire [1:0]  cpu_data_size ;
wire [31:0] cpu_data_wdata;
wire [31:0] cpu_data_rdata;
wire        cpu_data_addr_ok;
wire        cpu_data_data_ok;

mips_with_sram_like mips_with_sram_like(
    .clk(clk),.rst(rst),
    .ext_int(ext_int),

    //instr
    .inst_req(cpu_inst_req),
    .inst_wr(cpu_inst_wr),
    .inst_size(cpu_inst_size),
    .inst_addr(cpu_inst_addr),
    .inst_wdata(cpu_inst_wdata),
    .inst_addr_ok(cpu_inst_addr_ok),
    .inst_data_ok(cpu_inst_data_ok),
    .inst_rdata(cpu_inst_rdata),

    //data
    .data_req(cpu_data_req),
    .data_wr(cpu_data_wr),
    .data_size(cpu_data_size),
    .data_addr(cpu_data_addr),
    .data_wdata(cpu_data_wdata),
    .data_addr_ok(cpu_data_addr_ok),
    .data_data_ok(cpu_data_data_ok),
    .data_rdata(cpu_data_rdata),

    //debug
    .debug_wb_pc(debug_wb_pc),      
    .debug_wb_rf_wen(debug_wb_rf_wen),
    .debug_wb_rf_wnum(debug_wb_rf_wnum), 
    .debug_wb_rf_wdata(debug_wb_rf_wdata)


);

wire [31:0] cpu_inst_paddr;
wire [31:0] cpu_data_paddr;
wire no_dcache;


mmu mmu(
    .inst_vaddr(cpu_inst_addr ),
    .inst_paddr(cpu_inst_paddr),
    .data_vaddr(cpu_data_addr ),
    .data_paddr(cpu_data_paddr),
    .no_dcache (no_dcache    )
);

cpu_axi_interface cpu_axi_interface(
    .clk(clk),
    .resetn(~rst),

    .inst_req       (cpu_inst_req  ),
    .inst_wr        (cpu_inst_wr   ),
    .inst_size      (cpu_inst_size ),
    .inst_addr      (cpu_inst_paddr ),
    .inst_wdata     (cpu_inst_wdata),
    .inst_rdata     (cpu_inst_rdata),
    .inst_addr_ok   (cpu_inst_addr_ok),
    .inst_data_ok   (cpu_inst_data_ok),

    .data_req       (cpu_data_req  ),
    .data_wr        (cpu_data_wr   ),
    .data_size      (cpu_data_size ),
    .data_addr      (cpu_data_paddr ),
    .data_wdata     (cpu_data_wdata ),
    .data_rdata     (cpu_data_rdata),
    .data_addr_ok   (cpu_data_addr_ok),
    .data_data_ok   (cpu_data_data_ok),

    .arid(arid),
    .araddr(araddr),
    .arlen(arlen),
    .arsize(arsize),
    .arburst(arburst),
    .arlock(arlock),
    .arcache(arcache),
    .arprot(arprot),
    .arvalid(arvalid),
    .arready(arready),

    .rid(rid),
    .rdata(rdata),
    .rresp(rresp),
    .rlast(rlast),
    .rvalid(rvalid),
    .rready(rready),

    .awid(awid),
    .awaddr(awaddr),
    .awlen(awlen),
    .awsize(awsize),
    .awburst(awburst),
    .awlock(awlock),
    .awcache(awcache),
    .awprot(awprot),
    .awvalid(awvalid),
    .awready(awready),

    .wid(wid),
    .wdata(wdata),
    .wstrb(wstrb),
    .wlast(wlast),
    .wvalid(wvalid),
    .wready(wready),

    .bid(bid),
    .bresp(bresp),
    .bvalid(bvalid),
    .bready(bready)
);


endmodule