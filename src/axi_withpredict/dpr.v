module dual_port_ram #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 9
) (
    input wire clk,
    input wire we_a, we_b,
    input wire [ADDR_WIDTH-1 : 0] addr_a, addr_b,
    input wire [DATA_WIDTH-1 : 0] din_a, din_b,
    output reg [DATA_WIDTH-1 : 0] dout_a, dout_b
);
    // RAM 存储
    reg [DATA_WIDTH-1 : 0] ram [(1 << ADDR_WIDTH) - 1 : 0];

    // 端口 A 的操作
    always @(posedge clk) begin
        if (we_a) begin
            ram[addr_a] <= din_a;
        end
        dout_a <= ram[addr_a];
    end

    // 端口 B 的操作
    always @(posedge clk) begin
        if (we_b) begin
            ram[addr_b] <= din_b;
        end
        dout_b <= ram[addr_b];
    end
endmodule
