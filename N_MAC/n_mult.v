//乘法器阵列
`include "extern.v"
module n_mult(mult_clk,rst_n,fin_a,fin_b,dout);

input mult_clk,rst_n;
input [`DWIDTH-1:0] fin_a,fin_b;
output [`DWIDTH-1:0] dout;

genvar gv_i;
generate
	for(gv_i = 0; gv_i < `CELL_N;gv_i = gv_i + 1)
	begin: float_multiplier
		float_mult u_fm(mult_clk,rst_n,
							fin_a[gv_i*`D_LEN+`D_LEN-1:gv_i*`D_LEN],
							fin_b[gv_i*`D_LEN+`D_LEN-1:gv_i*`D_LEN],
							 dout[gv_i*`D_LEN+`D_LEN-1:gv_i*`D_LEN]);
	end
endgenerate
endmodule
