module cache (
    input wire clk, rst,
    //mips core
    input         cpu_inst_req     ,
    input         cpu_inst_wr      ,
    input  [1 :0] cpu_inst_size    ,
    input  [31:0] cpu_inst_addr    ,
    input  [31:0] cpu_inst_wdata   ,
    output [31:0] cpu_inst_rdata   ,
    output        cpu_inst_addr_ok ,
    output        cpu_inst_data_ok ,

    input         cpu_data_req     ,
    input         cpu_data_wr      ,
    input  [1 :0] cpu_data_size    ,
    input  [31:0] cpu_data_addr    ,
    input  [31:0] cpu_data_wdata   ,
    output [31:0] cpu_data_rdata   ,
    output        cpu_data_addr_ok ,
    output        cpu_data_data_ok ,

    //axi interface
    // icache
    // ar
    output wire [31:0] i_araddr         ,
    output wire [3 :0] i_arlen          ,
    output wire [2 :0] i_arsize         ,
    output wire        i_arvalid        ,
    input  wire        i_arready        ,
    // r
    input  wire [31:0] i_rdata          ,
    input  wire        i_rlast          ,
    input  wire        i_rvalid         ,
    output wire        i_rready         ,

    // dcache
    // ar
    output wire [31:0] d_araddr       ,
    output wire [3 :0] d_arlen        ,
    output wire [2 :0] d_arsize       ,
    output wire        d_arvalid      ,
    input  wire        d_arready      ,
    // r
    input  wire [31:0] d_rdata        ,
    input  wire        d_rlast        ,
    input  wire        d_rvalid       ,
    output wire        d_rready       ,
    // aw
    output wire [31:0] d_awaddr       ,
    output wire [3 :0] d_awlen        ,
    output wire [2 :0] d_awsize       ,
    output wire        d_awvalid      ,
    input  wire        d_awready      ,
    // w
    output wire [31:0] d_wdata        ,
    output wire [3 :0] d_wstrb        ,
    output wire        d_wlast        ,
    output wire        d_wvalid       ,
    input  wire        d_wready       ,
    // b
    input  wire        d_bvalid       ,
    output wire        d_bready       
);

    // i_cache_burst i_cache(
    //     .clk(clk), .rst(rst),                  
        
    //     // lsram
    //     .cpu_inst_req     (cpu_inst_req     ),
    //     .cpu_inst_wr      (cpu_inst_wr      ),
    //     .cpu_inst_size    (cpu_inst_size    ),
    //     .cpu_inst_addr    (cpu_inst_addr    ),
    //     .cpu_inst_wdata   (cpu_inst_wdata   ),
    //     .cpu_inst_rdata   (cpu_inst_rdata   ),
    //     .cpu_inst_addr_ok (cpu_inst_addr_ok ),
    //     .cpu_inst_data_ok (cpu_inst_data_ok ),

    //     // axi interface
    //     // ar
    //     .araddr (i_araddr ),
    //     .arlen  (i_arlen  ),
    //     .arsize (i_arsize ),
    //     .arvalid(i_arvalid),
    //     .arready(i_arready),
    //     // r
    //     .rdata  (i_rdata  ),
    //     .rlast  (i_rlast  ),
    //     .rvalid (i_rvalid ),
    //     .rready (i_rready )
    // );
    wire          tmp_cache_inst_req     ;
    wire          tmp_cache_inst_wr      ;
    wire   [1 :0] tmp_cache_inst_size    ;
    wire   [31:0] tmp_cache_inst_addr    ;
    wire   [31:0] tmp_cache_inst_wdata   ;
    wire   [31:0] tmp_cache_inst_rdata   ;
    wire          tmp_cache_inst_addr_ok ;
    wire          tmp_cache_inst_data_ok ;

    i_cache i_cache(
    .clk(clk), .rst(rst),
    //mips core
    .cpu_inst_req(cpu_inst_req)     ,
    .cpu_inst_wr(cpu_inst_wr)      ,
    .cpu_inst_size(cpu_inst_size)    ,
    .cpu_inst_addr(cpu_inst_addr)    ,
    .cpu_inst_wdata(cpu_inst_wdata)   ,
    .cpu_inst_rdata(cpu_inst_rdata)   ,
    .cpu_inst_addr_ok(cpu_inst_addr_ok) ,
    .cpu_inst_data_ok(cpu_inst_data_ok) ,

    //axi interface
    .cache_inst_req(tmp_cache_inst_req)     ,
    .cache_inst_wr(tmp_cache_inst_wr)      ,
    .cache_inst_size(tmp_cache_inst_size)    ,
    .cache_inst_addr(tmp_cache_inst_addr)    ,
    .cache_inst_wdata(tmp_cache_inst_wdata)   ,
    .cache_inst_rdata(tmp_cache_inst_rdata)   ,
    .cache_inst_addr_ok(tmp_cache_inst_addr_ok) ,
    .cache_inst_data_ok(tmp_cache_inst_data_ok) 
    );

    sram_like_to_axi sram_like_to_axi(
    .clk(clk), .rst(rst),
    // sram_like
    .sraml_req(tmp_cache_inst_req)     ,
    .sraml_wr(tmp_cache_inst_wr)      ,
    .sraml_size(tmp_cache_inst_size)    ,
    .sraml_addr(tmp_cache_inst_addr)    ,
    .sraml_wdata(tmp_cache_inst_wdata)   ,
    .sraml_rdata(tmp_cache_inst_rdata)   ,
    .sraml_addr_ok(tmp_cache_inst_addr_ok) ,
    .sraml_data_ok(tmp_cache_inst_data_ok) ,

    // axi
    // ar
    .araddr(i_araddr)       ,
    .arlen(i_arlen)        ,
    .arsize(i_arsize)       ,
    .arvalid(i_arvalid)      ,
    .arready(i_arready)      ,
    // r
    .rdata(i_rdata)        ,
    .rlast(i_rlast)        ,
    .rvalid(i_rvalid)       ,
    .rready(i_rready)           
    );

    // d_cache_burst d_cache(
   d_cache_4waywb_burst d_cache(
        .clk(clk), .rst(rst),
        
        // lsram
        .cpu_data_req    (cpu_data_req    ), 
        .cpu_data_wr     (cpu_data_wr     ), 
        .cpu_data_size   (cpu_data_size   ), 
        .cpu_data_addr   (cpu_data_addr   ),
        .cpu_data_wdata  (cpu_data_wdata  ),
        .cpu_data_rdata  (cpu_data_rdata  ), 
        .cpu_data_addr_ok(cpu_data_addr_ok), 
        .cpu_data_data_ok(cpu_data_data_ok),
        
        // axi interface
        // ar
        .araddr  (d_araddr  ),
        .arlen   (d_arlen   ),
        .arsize  (d_arsize  ),
        .arvalid (d_arvalid ),
        .arready (d_arready ),
        // r
        .rdata   (d_rdata   ),
        .rlast   (d_rlast   ),
        .rvalid  (d_rvalid  ),
        .rready  (d_rready  ),
        // aw
        .awaddr  (d_awaddr  ),
        .awlen   (d_awlen   ),
        .awsize  (d_awsize  ),
        .awvalid (d_awvalid ),
        .awready (d_awready ),
        // w
        .wdata   (d_wdata   ),
        .wstrb   (d_wstrb   ),
        .wlast   (d_wlast   ),
        .wvalid  (d_wvalid  ),
        .wready  (d_wready  ),
        // b
        .bvalid  (d_bvalid  ),
        .bready  (d_bready  )
    );
endmodule