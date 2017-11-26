module float2int(clk,rst_n,float_in,int_out);

parameter E_bit = 8,F_bit = 23,INT_WIDTH = 32;
parameter E_int_ref = {(E_bit-1){1'b1}}+F_bit;			//指数零偏

input wire clk,rst_n;
input wire[E_bit+F_bit:0] float_in;
output reg[INT_WIDTH-1:0] int_out;

reg [INT_WIDTH-1:0] abs_buf;

wire [E_bit-1:0] f_e = float_in[E_bit+F_bit-1:F_bit];
wire [F_bit:0] f_f = {1'b1,float_in[F_bit-1:0]};	//规范化转非规范化，尾数高位扩充为1
wire f_s = float_in[E_bit+F_bit];

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		abs_buf <= 0;
	end
	else begin
		if (f_e == E_int_ref)begin
			abs_buf = f_f;
		end
		else if(f_e > E_int_ref) begin
			abs_buf = f_f << (f_e-E_int_ref);
		end
		else begin
			abs_buf = f_f >> (E_int_ref-f_e);
		end
		
		if(f_s) begin
			int_out <= ~abs_buf+1;
		end
		else begin
			int_out <= abs_buf;
		end
	end
end
endmodule
