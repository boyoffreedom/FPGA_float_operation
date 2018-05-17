//加法器阵列
`include "extern.v"
module n_adder(clk,rst_n,acc_start,acc_finish,
				mult_out,mult_wen,adder_out,acc_out);


input clk,rst_n,acc_start;
output acc_finish;
input mult_wen;
input [`DWIDTH-1:0] mult_out;
output [`DWIDTH-1:0] adder_out;
output [`D_LEN-1:0] acc_out;
wire [`DWIDTH-1:0] mult_din = (mult_wen==0)?0:mult_out;
wire [2*`DWIDTH-1:0] din = (acc_mux == 0)?{mult_din,adder_out}:{{(2*`DWIDTH-2*`D_LEN){1'b0}},acc_buf[1],acc_buf[0]};

reg acc_finish;
reg [`D_LEN-1:0] acc_out;
reg [`D_LEN-1:0] acc_buf[2:0];
reg acc_mux;
reg[4:0] acc_state;
reg[12:0] acc_loop;
//累加状态机
always @(negedge clk or negedge rst_n)begin
	if(!rst_n)begin
		acc_buf[0] <= 0;
		acc_buf[1] <= 0;
		acc_buf[2] <= 0;
		acc_finish <= 1;
		acc_state <= 0;
		acc_loop <= 0;
		acc_mux <= 0;
	end
	else begin
		case(acc_state)
		0:begin
			if(acc_start)begin				//控制器发出累加触发（乘法器已经完成运算）
				acc_state <= 1;
				acc_finish <= 0;
				acc_loop <= `CELL_N>>1;		//获取累加循环次数
				acc_mux <= 0;					//数据选择为加法器输出数据
			end
			else begin
				acc_mux <= 0;
				acc_state <= 0;
			end
		end
		1:begin
			if(acc_loop == 0)begin			//组内加法器循环完成，目前只剩三个有效数据保留在三级流水线上
				acc_buf[0] <= 0;				//使用3个缓存变量去保存这三个数据
				acc_buf[1] <= 0;
				acc_buf[2] <= 0;
				acc_state <= 5;
			end
			else begin							//所有数据向第一个加法器内汇聚
				acc_loop <= acc_loop >> 1;
				acc_state <= 2;
			end
		end
		2:acc_state <= 3;
		3:acc_state <= 1;
		
		5:begin									//装载三级流水线的三个数据
			acc_state <= 6;
			acc_buf[0] <= adder_out[`D_LEN-1:0];
		end
		6:begin
			acc_state <= 7;
			acc_buf[1] <= adder_out[`D_LEN-1:0];
		end
		7:begin
			acc_state <= 9;
			acc_mux <= 1;
			acc_buf[2] <= adder_out[`D_LEN-1:0];
		end
//		8:begin									//选择输入为三级流水线缓存的数据，先进行前两个数据的加法运算
//			acc_mux <= 1;
//			acc_state <= 9;
//		end
		9:acc_state <= 10;
		10:acc_state <= 12;
		12:begin									//再进行后两个数据的加法运算
			acc_buf[0] <= adder_out[`D_LEN-1:0];
			acc_buf[1] <= acc_buf[2];
			acc_state <= 13;
		end
		13:acc_state <= 14;
		14:acc_state <= 16;
		16:begin									//运算结束
			acc_finish <= 1;
			acc_mux <= 0;
			acc_state <= 0;
		end
		default:acc_state <= 0;
		endcase
	end
end

//完成累加运算，输出累加结果
always @(posedge acc_finish or negedge rst_n)begin
	if(!rst_n)begin
		acc_out <= 0;
	end
	else begin
		acc_out <= adder_out[`D_LEN-1:0];
	end
end
//生成多个加法器
genvar gv_i;
generate
	for(gv_i = 0; gv_i < `CELL_N;gv_i = gv_i + 1)
	begin: float_adder
		float_adder u_fm(clk,rst_n,
							din[gv_i*2*`D_LEN+`D_LEN-1:gv_i*2*`D_LEN],
							din[gv_i*2*`D_LEN+2*`D_LEN-1:gv_i*2*`D_LEN+`D_LEN],
							adder_out[gv_i*`D_LEN+`D_LEN-1:gv_i*`D_LEN]);
	end
endgenerate
endmodule
