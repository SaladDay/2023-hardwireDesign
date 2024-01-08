`timescale 1ns / 1ps
`include "../defines2.vh"

module exceptdec(
    input wire clk,                //时钟信号
    input wire rst,                //复位信号
    input wire[5:0] ext_int,       //cpu外部传入，判断硬件中断
    input wire[31:0] cp0_status,   //CP0的Status寄存器值，判断中断是否屏蔽、全局中断是否使能、处理器是否处于例外处理
    input wire[31:0] cp0_cause,    //CP0的Cause寄存器值，判断软件中断
    input wire[31:0] cp0_epc,      //CP0的Epc寄存器值
    input wire is_syscallM,        //SYSCALL指令
    input wire is_breakM,          //BREAK指令
    input wire is_eretM,           //ERET指令
    input wire is_AdEL_pcM,        //取指pc是否对齐
    input wire is_AdEL_dataM,      //Load指令访存地址是否对齐
    input wire is_AdES_dataM,      //Store指令访存地址是否对齐
    input wire is_overflowM,       //是否整型溢出
    input wire is_invalidM,        //是否保留指令（未实现指令）

    output reg is_except,         //是否触发例外
    output reg[31:0] except_type,  //触发例外类型
    output reg[31:0] except_pc     //触发例外时的下一pc,所有的例外处理统一入口地址32'hBFC00380
    );

    always @(*) begin
        if(rst)begin
            is_except <= 1'b0;
            except_type <= 32'hffffffff;
            except_pc <= 32'b0;
        end else begin
            if((cp0_status[15:8] & {ext_int,cp0_cause[9:8]}) != 8'h00 &
                    (cp0_status[1] == 1'b0) & cp0_status[0] == 1'b1)begin 
                //软硬件中断
                is_except <= 1'b1;
                except_type <= 32'h00000000;
                except_pc <= `EXCEPT_PC;    
            end else if(is_AdEL_pcM | is_AdEL_dataM)begin 
                // 取指非对齐或Load非对齐
                is_except <= 1'b1;
                except_type <= 32'h00000004;
                except_pc <= `EXCEPT_PC;    
            end else if(is_AdES_dataM)begin 
                // Store非对齐
                is_except <= 1'b1;
                except_type <= 32'h00000005;
                except_pc <= `EXCEPT_PC;    
            end else if(is_syscallM)begin 
                // SYSCALL
                is_except <= 1'b1;
                except_type <= 32'h00000008;
                except_pc <= `EXCEPT_PC;    
            end else if(is_breakM)begin 
                // BREAK
                is_except <= 1'b1;
                except_type <= 32'h00000009;
                except_pc <= `EXCEPT_PC;   
            end else if(is_invalidM)begin 
                // 保留指令（未实现指令）
                is_except <= 1'b1;
                except_type <= 32'h0000000a;
                except_pc <= `EXCEPT_PC;   
            end else if(is_overflowM)begin 
                // 整型溢出
                is_except <= 1'b1;
                except_type <= 32'h0000000c;
                except_pc <= `EXCEPT_PC;   
            end
             else if(is_eretM)begin 
                // ERET
                is_except <= 1'b1;
                except_type <= 32'h0000000e;
                except_pc <= cp0_epc;  
            end else begin
                is_except <= 1'b0;
                except_type <= 32'hffffffff;
                except_pc <= 32'b0;
             end
        end
    end
endmodule