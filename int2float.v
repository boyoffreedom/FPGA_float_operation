module int2float(clk,rst_n,int_in,float_out);

parameter E_bit = 8,F_bit = 23,INT_WIDTH = 32;
parameter E_ref = {(E_bit-1){1'b1}};			//指数零偏

input wire clk,rst_n;
input wire[INT_WIDTH-1:0] int_in;

output wire[E_bit+F_bit:0] float_out;

//浮点符号、指数、尾数
reg f_s;
reg[E_bit-1:0] f_e;
reg[F_bit-1:0] f_f;
assign float_out = {f_s,f_e,f_f};		//浮点拼接

wire int_s = int_in[INT_WIDTH-1];		//整数符号位
wire[INT_WIDTH-1:0] abs_int = int_s?(~int_in+1):int_in;
reg[INT_WIDTH-1:0] int_shift_buf;
reg[E_bit-1:0] e_shift;
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		f_s <= 0;
		f_e <= E_ref;
		f_f <= 0;
	end
	else begin
		if(e_shift > F_bit) begin		//整数最高位位置超出尾数范围，右移并规范化
			int_shift_buf = abs_int>>(e_shift-F_bit);
		end
		else begin							//整数最高位位置小于尾数规范化最高位，左移
			int_shift_buf = abs_int<<(F_bit-e_shift);
		end
		f_e <= E_ref + e_shift;
		f_f = int_shift_buf[F_bit-1:0];
		f_s <= int_s;
	end
end

//该代码由python生成，当然，不嫌麻烦也可以手动
always @(abs_int) begin
	casex(abs_int)
		32'b1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx: e_shift=7'd31;
		32'b01xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx: e_shift=7'd30;
		32'b001xxxxxxxxxxxxxxxxxxxxxxxxxxxxx: e_shift=7'd29;
		32'b0001xxxxxxxxxxxxxxxxxxxxxxxxxxxx: e_shift=7'd28;
		32'b00001xxxxxxxxxxxxxxxxxxxxxxxxxxx: e_shift=7'd27;
		32'b000001xxxxxxxxxxxxxxxxxxxxxxxxxx: e_shift=7'd26;
		32'b0000001xxxxxxxxxxxxxxxxxxxxxxxxx: e_shift=7'd25;
		32'b00000001xxxxxxxxxxxxxxxxxxxxxxxx: e_shift=7'd24;
		32'b000000001xxxxxxxxxxxxxxxxxxxxxxx: e_shift=7'd23;
		32'b0000000001xxxxxxxxxxxxxxxxxxxxxx: e_shift=7'd22;
		32'b00000000001xxxxxxxxxxxxxxxxxxxxx: e_shift=7'd21;
		32'b000000000001xxxxxxxxxxxxxxxxxxxx: e_shift=7'd20;
		32'b0000000000001xxxxxxxxxxxxxxxxxxx: e_shift=7'd19;
		32'b00000000000001xxxxxxxxxxxxxxxxxx: e_shift=7'd18;
		32'b000000000000001xxxxxxxxxxxxxxxxx: e_shift=7'd17;
		32'b0000000000000001xxxxxxxxxxxxxxxx: e_shift=7'd16;
		32'b00000000000000001xxxxxxxxxxxxxxx: e_shift=7'd15;
		32'b000000000000000001xxxxxxxxxxxxxx: e_shift=7'd14;
		32'b0000000000000000001xxxxxxxxxxxxx: e_shift=7'd13;
		32'b00000000000000000001xxxxxxxxxxxx: e_shift=7'd12;
		32'b000000000000000000001xxxxxxxxxxx: e_shift=7'd11;
		32'b0000000000000000000001xxxxxxxxxx: e_shift=7'd10;
		32'b00000000000000000000001xxxxxxxxx: e_shift=7'd9;
		32'b000000000000000000000001xxxxxxxx: e_shift=7'd8;
		32'b0000000000000000000000001xxxxxxx: e_shift=7'd7;
		32'b00000000000000000000000001xxxxxx: e_shift=7'd6;
		32'b000000000000000000000000001xxxxx: e_shift=7'd5;
		32'b0000000000000000000000000001xxxx: e_shift=7'd4;
		32'b00000000000000000000000000001xxx: e_shift=7'd3;
		32'b000000000000000000000000000001xx: e_shift=7'd2;
		32'b0000000000000000000000000000001x: e_shift=7'd1;
		32'b00000000000000000000000000000001: e_shift=7'd0;
		default: e_shift = 7'd0;
	endcase
end

endmodule

