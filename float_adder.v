module float_adder(clk,rst_n,add_a,add_b,adder_out);

//bit=s+e+f			s = 1;e = E_bit;f=F_bit;
//定义参数
parameter E_bit = 8,F_bit=23;

//运算参数，根据定义生成，一般不需要更改。
parameter E_ref = {(E_bit-1){1'b1}};
parameter E_max = {(E_bit){1'b1}};

input wire[E_bit+F_bit:0] add_a,add_b;			//符号位1 指数位 E_bit 尾数位F_bit
output wire[E_bit+F_bit:0] adder_out;
input rst_n,clk;			//com == 0: 加add_a; com == 1: 加内部寄存器

assign adder_out = {add_s2,add_e2,add_f2};
//assign adder_out = {{(E_bit+1){1'b0}},add_f2};

//输入规范化解码
wire [E_bit-1:0] a_e = add_a[E_bit+F_bit-1:F_bit];
wire [E_bit-1:0] b_e = add_b[E_bit+F_bit-1:F_bit];
wire [2*F_bit+1:0] a_f = {2'b01,add_a[F_bit-1:0],{F_bit{1'b0}}};	//规范化转非规范化，尾数高位扩充为1，低位扩充用于移位
wire [2*F_bit+1:0] b_f = {2'b01,add_b[F_bit-1:0],{F_bit{1'b0}}};	//规范化转非规范化，尾数高位扩充为1，低位扩充用于移位
wire 				  a_s = add_a[E_bit+F_bit];
wire 				  b_s = add_b[E_bit+F_bit];

reg a_s0,b_s0,add_s1,add_s2;

reg[E_bit-1:0] add_e0;					//各级流水线指数暂存
reg[E_bit-1:0] add_e1;
reg[E_bit-1:0] add_e2;

reg[2*F_bit+1:0] a_f0,b_f0;					 //各级流水线尾数暂存
reg[2*F_bit+1:0] add_f1;									
reg[F_bit-1:0] add_f2;

wire[2*F_bit+1:0] sub_shift_f1 = (add_f1 << (sub_shift-1'b1));
reg[E_bit-1:0] sub_shift;

//LEVEL0:对阶，尾数移位，交换
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin					//复位流水线级各参数
		a_s0 <= 0;
		b_s0 <= 0;
		add_e0 <= 0;
		a_f0 <= 0;
		b_f0 <= 0;
	end
	else begin
		if((a_e < b_e)|| (a_e == b_e && a_f < b_f)) begin			//b数大于a数，或者ab同阶，尾数a<b，在第一级流水线交换，以后流水线都按照a>=b运算
			a_s0 <= b_s;				//ab符号交换
			b_s0 <= a_s;				//ab符号交换
			add_e0 <= b_e;				//取对齐后的阶数
			a_f0 <= b_f;				//ab尾数交换
			b_f0 <= a_f>>(b_e-a_e);	//a阶数小于b阶数，a数右移对阶
		end
		else begin
			a_s0 <= a_s;			//a阶数大于b，b右移
			b_s0 <= b_s;
			add_e0 <= a_e;
			a_f0 <= a_f;
			b_f0 <= b_f>>(a_e-b_e);	//a数大于等于b数，b数右移对阶
		end
	end
end


//LEVEL1: 尾数运算
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin					//复位流水线级各参数
		add_e1 <= 0;
		add_f1 <= 0;
		add_s1 <= 0;
	end
	else begin
		if(a_s0 == b_s0) begin		//符号相等，
			add_f1 <= a_f0 + b_f0;
		end
		else begin //符号相异，减法运算
			add_f1 <= a_f0 - b_f0;
		end
		add_s1 <= a_s0;
		add_e1 <= add_e0;
	end
end

//LEVEL3 : 规范化：加法进位规范和减法借位规范
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin					//复位流水线级各参数
		add_e2 <= 0;
		add_f2 <= 0;
		add_s2 <= 0;
	end
	else begin
		if(add_f1[2*F_bit+1]) begin			//最高位为1尾数进位
			if(add_e2 == E_max) begin		//溢出，全给1
				add_f2 <= {F_bit{1'b1}};
				add_e2 <= {E_bit{1'b1}};
			end
			else begin							//否则规范化并进位
				add_f2 <= add_f1[2*F_bit:F_bit+1];
				add_e2 <= add_e1+1'b1;
			end
		end
		else begin
			add_f2 <= sub_shift_f1[2*F_bit-1:F_bit];//add_f1[2*F_bit-1:F_bit];
			add_e2 <= add_e1 - (sub_shift-1'b1);//add_e1;
		end
		add_s2 <= add_s1;
	end
end

//可定制优先编码器查找减法运算后的最高位，用于规格化，此代码由python生成
//使用casex语句极大限度的并行化，使用verilog for循环生成门延时非常恐怖
always @(add_f1) begin
	casex(add_f1[2*F_bit+1:F_bit+1])
		24'b1xxxxxxxxxxxxxxxxxxxxxxx: sub_shift=7'h0;
		24'b01xxxxxxxxxxxxxxxxxxxxxx: sub_shift=7'h1;
		24'b001xxxxxxxxxxxxxxxxxxxxx: sub_shift=7'h2;
		24'b0001xxxxxxxxxxxxxxxxxxxx: sub_shift=7'h3;
		24'b00001xxxxxxxxxxxxxxxxxxx: sub_shift=7'h4;
		24'b000001xxxxxxxxxxxxxxxxxx: sub_shift=7'h5;
		24'b0000001xxxxxxxxxxxxxxxxx: sub_shift=7'h6;
		24'b00000001xxxxxxxxxxxxxxxx: sub_shift=7'h7;
		24'b000000001xxxxxxxxxxxxxxx: sub_shift=7'h8;
		24'b0000000001xxxxxxxxxxxxxx: sub_shift=7'h9;
		24'b00000000001xxxxxxxxxxxxx: sub_shift=7'h10;
		24'b000000000001xxxxxxxxxxxx: sub_shift=7'h11;
		24'b0000000000001xxxxxxxxxxx: sub_shift=7'h12;
		24'b00000000000001xxxxxxxxxx: sub_shift=7'h13;
		24'b000000000000001xxxxxxxxx: sub_shift=7'h14;
		24'b0000000000000001xxxxxxxx: sub_shift=7'h15;
		24'b00000000000000001xxxxxxx: sub_shift=7'h16;
		24'b000000000000000001xxxxxx: sub_shift=7'h17;
		24'b0000000000000000001xxxxx: sub_shift=7'h18;
		24'b00000000000000000001xxxx: sub_shift=7'h19;
		24'b000000000000000000001xxx: sub_shift=7'h20;
		24'b0000000000000000000001xx: sub_shift=7'h21;
		24'b00000000000000000000001x: sub_shift=7'h22;
		24'b000000000000000000000001: sub_shift=7'h23;
		default: sub_shift = 7'h24;
	endcase
end

endmodule
