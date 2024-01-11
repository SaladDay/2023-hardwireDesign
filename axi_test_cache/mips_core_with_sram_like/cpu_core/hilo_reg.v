module hilo_reg(
	input wire clk,rst,
	input wire we, //写使能
	input wire[63:0] hilo_in, //写入值
	output reg[63:0] hilo_out //读出值
    );

	always @(posedge clk) begin
        if(rst)begin
            hilo_out <= 0;
        end
		else if(we) begin
			 hilo_out <= hilo_in;
		end
		else begin
			hilo_out <= hilo_out;
		end
	end

endmodule