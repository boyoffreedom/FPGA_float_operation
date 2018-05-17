//超参数定义
	//浮点位数定义，加法器需重新定制编码器
`define E_bit 8
`define F_bit 23
`define D_LEN (`E_bit+`F_bit+1)
	//单次运算数据长度、运算单元数量、运算单元输出地址位数定义
`define CELL_N 4						//运算单元的数量
`define ADDR_L (2**`AWIDTH-1)		//单次触发最大循环调用运算单元次数

	//内部RAM参数定义
`define DWIDTH (`CELL_N*(`E_bit+`F_bit+1))	//内部RAM数据总线宽度

//神经网络存储空间定义
`define OAWIDTH 5										//外部RAM地址线宽


