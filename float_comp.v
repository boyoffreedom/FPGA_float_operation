module float_comp(rst_n,clk,float_a,float_b,gt,eq,lt);

parameter E_bit = 8,F_bit = 23;

input clk,rst_n;
input [F_bit+E_bit:0] float_a,float_b;
output wire gt,eq,lt;

wire a_s = float_a[F_bit+E_bit];
wire b_s = float_b[F_bit+E_bit];
wire[E_bit-1:0] a_e = float_a[F_bit+E_bit-1:F_bit];
wire[E_bit-1:0] b_e = float_b[F_bit+E_bit-1:F_bit];
wire[F_bit-1:0] a_f = float_a[F_bit-1:0];
wire[F_bit-1:0] b_f = float_b[F_bit-1:0];

reg great_than,equal;

//great_than equal gt eq lt
//     0       0   0  0  1
//     1       0   1  0  0
//     0       1   0  1  0

assign gt = great_than;
assign eq = equal;
assign lt = (~great_than)&(~equal);

always @(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		great_than <= 0;
		equal <= 0;
	end
	else begin
		great_than <= 0;
		equal <= 0;
		if(a_s == b_s) begin										//同符号时
			if(a_e > b_e) great_than <= 1'b1^a_s; 			//a指数大于b
			else if(a_e < b_e) great_than <= 1'b0^a_s;	//a指数小于b
			else begin												//尾数相同时
				if(a_f > b_f) great_than <= 1'b1^a_s;		//a尾数大于b
				else if(a_f < b_f) great_than <= 1'b0^a_s;	//a尾数小于b
				else	equal <= 1'b1;								//符号、指数和尾数均相等，三个数相等
			end
		end
		else if(a_s == 0)										//符号相异，a为正
			great_than <= 1'b1;
		else
			great_than <= 1'b0;
	end
end
endmodule
