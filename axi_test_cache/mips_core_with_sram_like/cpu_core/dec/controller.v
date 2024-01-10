
`include "../defines2.vh"
`timescale 1ns / 1ps
module controller(
    input wire [31:0] instrD,

    output wire[4:0] alucontrolD,
    output wire memtoregD,memwriteD,branchD,alusrcD,regwriteD,jumpD,hilo_writeD,jbralD,jrD,cp0_writeD,is_invalidD,
    output wire hilotoregD,cp0toregD,
	output wire [1:0] regdstD,
	output wire memread,
	output wire [1:0] mfhi_lo
);
	wire [5:0] opD;
	wire [5:0] functD;
	wire [4:0] rsD;
	wire [4:0] rtD;

	assign opD = instrD[31:26];
	assign functD = instrD[5:0];
	assign rsD = instrD[25:21];
	assign rtD = instrD[20:16];

    maindec md(
		opD,
		functD,
		rsD,
		rtD,
		memtoregD,memwriteD,
		branchD,alusrcD,
		regdstD,regwriteD,
		jumpD,
		hilo_writeD,
		jbralD,
		jrD,
		cp0_writeD,
		is_invalidD,
		hilotoregD,
		cp0toregD,
		memread,
		mfhi_lo
		);

    aludec ad(functD,opD,rsD,rtD,alucontrolD);
endmodule