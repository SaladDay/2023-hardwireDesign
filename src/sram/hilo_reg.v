module hilo_reg(
	input wire clk,rst,
	input wire we, //写使能
	input wire[63:0] hilo_in, //写入值
	output wire[63:0] hilo_out //读出值
    );
	reg [63:0] hilo_reg; //HILO寄存器
	always @(negedge clk) begin
        if(rst)begin
            hilo_reg <= 0;
        end
		else if(we) begin
			 hilo_reg <= hilo_in;
		end
	end
	assign hilo_out = hilo_reg;
endmodule