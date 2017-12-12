module float_inrange(rst_n,clk,float_lower,float_upper,float_in,inrange);
//查找浮点数是否在相应的范围内,统一左开右闭
parameter E_bit = 8,F_bit = 23;

input clk,rst_n;
input [F_bit+E_bit:0] float_lower,float_upper,float_in;
output wire inrange;

//解码
wire l_s = float_lower[F_bit+E_bit];
wire u_s = float_upper[F_bit+E_bit];
wire i_s = float_in[F_bit+E_bit];

wire[E_bit-1:0] l_e = float_lower[F_bit+E_bit-1:F_bit];
wire[E_bit-1:0] u_e = float_upper[F_bit+E_bit-1:F_bit];
wire[E_bit-1:0] i_e = float_in[F_bit+E_bit-1:F_bit];

//比较大小可以不用规格化
wire[F_bit-1:0] l_f = float_lower[F_bit-1:0];
wire[F_bit-1:0] u_f = float_upper[F_bit-1:0];
wire[F_bit-1:0] i_f = float_in[F_bit-1:0];

reg gt_l,lt_u;
assign inrange = gt_l&lt_u;

//比较左边
always @(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		gt_l <= 0;
	end
	else begin
		gt_l <= 0;
		if(l_s == i_s) begin								//同符号时
			if(l_e < i_e) gt_l <= 1'b1^l_s; 			//i指数大于l
			else if(i_e < l_e) gt_l <= 1'b0^l_s;	//i指数小于l
			else begin										//指数相同时
				if(i_f > l_f) gt_l <= 1'b1^l_s;		//i尾数大于l
				else if(i_f < l_f) gt_l <= 1'b0^l_s;//i尾数小于l
				else gt_l <= 1'b0;						//尾数相等时，取0，左边为开区间
				
			end
		end
		else if(l_s == 0)									//符号相异，l为正
			gt_l <= 1'b1;
		else
			gt_l <= 1'b0;
		
	end
end

//比较右边
always @(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		lt_u <= 0;
	end
	else begin
		lt_u <= 0;
		if(u_s == i_s) begin									//同符号时
			if(u_e < i_e) lt_u <= 1'b0^u_s; 				//u指数大于i
			else if(i_e < u_e) lt_u <= 1'b1^u_s;		//u指数小于i
			else begin											//指数相同时
				if(i_f > u_f) lt_u <= 1'b0^l_s;			//u尾数大于i
				else if(i_f < u_f) lt_u <= 1'b1^l_s;	//i尾数小于u
				else lt_u <= 1'b1;
			end
		end
		else if(u_s == 0)										//符号相异，u为正
			lt_u <= 1'b1;
		else
			lt_u <= 1'b0;
		
	end
end
endmodule

