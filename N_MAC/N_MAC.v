`include "extern.v"
module N_MAC(clk,rst_n,ctrl,
				fin_a,fin_b,mult_out,adder_out,acc_out,mult_wen,acc_start,
				addr_rd,
				state);
//乘累加模块

input clk,rst_n;
input [15:0] ctrl;					//control控制位
input [`DWIDTH-1:0] fin_a,fin_b;								//浮点数输入
output [`DWIDTH-1:0] mult_out,adder_out;								//输出单次乘加结果
output [`D_LEN-1:0] acc_out;
output [12:0]addr_rd;  							//外接ram（存取乘法器与加法器直接输出值）地址
output [7:0]state;
output mult_wen,acc_start;
//用于标明乘累加器矩阵工作状态
//    6            5           4         3          2          1        0 
//{edb_busy,require_error,space_error,bus_crash,mult_busy,adder_busy,mac_finish};

//内部连线

wire [15:0] ctrl;
wire [`DWIDTH-1:0] mult_out;
wire [`DWIDTH-1:0] adder_out;
wire mult_clk,adder_clk;
wire mult_wen;
wire [12:0] addr_rd;
wire [7:0] state;
wire acc_finish;
wire mult_rst,adder_rst;
wire acc_start;

	n_mult u0(mult_clk,rst_n,fin_a,fin_b,mult_out);
	n_adder u1(adder_clk,adder_rst,acc_start,acc_finish,
				mult_out,mult_wen,adder_out,acc_out);
					
	n_mac_controller(clk,rst_n,ctrl,
							addr_rd,mult_rst,mult_clk,mult_wen,
							adder_rst,adder_clk,acc_start,acc_finish,
							state);
endmodule 

