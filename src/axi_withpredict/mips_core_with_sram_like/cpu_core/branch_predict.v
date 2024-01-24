module branch_predict (
    input clk,reset,

    input wire [31:0] pcF,
    input wire [31:0] instrF,
    output wire [31:0] pc_predict,

    input wire branch_taken,
    output wire predict_taken,
    output wire is_branch,
    input wire is_branchD

);
//------------------signal--------------------//
    wire [5:0] opF;
    wire [4:0] rtF;
    wire [15:0] offset;
   // wire is_branch;

//-------------------signal end---------------------//



//---------------logic control-----------------//
    assign opF =  instrF[31:26];
    assign rtF = instrF[20:16];
    assign offset = instrF[15:0];
    assign is_branch = (opF == `BEQ || opF == `BNE || opF == `BGTZ   || opF == `BLEZ );
    assign pc_predict = {{{16{offset[15]}}, offset} << 2} + pcF + 3'b100;

//----------------logic control end----------------//



//-----------------------branch predict--------------------//
    // 楗卞拰璁℃暟鍣?
    reg [1:0] counter;
   

    // 鍒濆鍖?
    initial begin
        counter <= 2'b01;
      //  predict_taken <= 1'b0;
    end
     reg aa = 1'b0;
    // 楂樼數骞虫椂閽熻竟娌胯Е鍙?
    always @(posedge clk or posedge reset) begin
        if (reset) begin
        // 澶嶄綅鏃堕噸鏂板垵濮嬪寲
        counter <= 2'b01;
        end else begin
     //    鏇存柊楗卞拰璁℃暟鍣?
        if (branch_taken & is_branchD) begin
            if (counter < 2'b11) counter <= counter + 1;
        end else if(~branch_taken & is_branchD) begin
            if (counter > 2'b00) counter <= counter - 1;
        end else counter <= counter;
        
//        if (branch_taken ) begin
//            if (counter < 2'b11) counter <= counter + 1;
//        end else begin
//            if (counter > 2'b00) counter <= counter - 1;
//           end


        // 鏍规嵁璁℃暟鍣ㄧ殑鍊奸娴嬪垎鏀槸鍚﹁閲囩撼
        aa <= ((counter == 2'b11) || (counter == 2'b10)) && is_branch;
        end
    end
    
    assign predict_taken =  aa & is_branch;
 //----------------------branch predict end-----------------------// 



endmodule