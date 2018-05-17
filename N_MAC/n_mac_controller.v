`include "extern.v"
//MAC_CONTROLLER used to allocate the work of each part, ram control,clock management and energy_save_mode
//requirement: each start trigger signal must keep at least two clock period
//There is a RAM inside MAC array used to accumulate

//乘累加器控制器，用于协调各部分工作，控制RAM，时钟管理与节能模式
//要求控制信号触发时至少保持两个时钟
//乘累加器阵列内部有一个ram用于累加模式
module n_mac_controller(clk,rst_n,ctrl,			//clock,reset,inner ram data mux,adder data mux  时钟、复位、内部RAM数据选择、加法器数据选择
							addr_rd,mult_rst,mult_clk,mult_wen,
							adder_rst,adder_clk,acc_start,acc_finish,
							state);					//multiplier and adder output clock and whole MAC state

input clk,rst_n;													//input clock and reset signal 输入时钟与复位信号
input [15:0]ctrl;													//control signal,set the MAC operation mode   控制器，规定乘累加矩阵实现哪种功能
input acc_finish;
output [12:0] addr_rd;											//乘法器运算结果输入地址
output mult_wen,mult_clk,mult_rst;
output adder_clk,adder_rst,acc_start;										//乘法器与加法器输出时钟
output [7:0]state;												//乘累加器矩阵的工作状态

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~//
//~~~~~~~~~~~~~~参     数     定     义     部     分~~~~~~~~~~~~~~~~~//
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~//

//时钟管理信号定义
reg mult_enable,adder_enable;									//时钟信号定义
assign mult_clk = clk&mult_enable;							//乘法器矩阵时钟使能
assign adder_clk = clk&adder_enable;						//加法器矩阵时钟使能

//ram地址信号
assign addr_rd = mult_addr_rd;								//addr_rd为读取外部ram地址
reg [12:0] mult_addr_rd;										//mult_addr_rd为乘法器读取地址
assign mult_wen = mult_wen_delay[2];

//控制与状态
reg ss_pedge_buf;
wire start_signal = ctrl[0]&(~ss_pedge_buf);				//the rising edge of start trigger signal 开始触发信号上升沿

reg mult_rst,adder_rst,acc_start;							//乘法器初始化，加法器初始化，累加器初始化

wire [12:0] ctrl_loop = ctrl[15:3];							//循环运行次数，主要控制乘法器与加法器的外部数据总线地址最大值与乘累加的循环次数
	//状态定义
	reg adder_busy,mult_busy,mac_finish;					//状态信号
	reg mult_edb_on;								//外部总线占用情况 edb=external data-bus
	wire edb_busy = mult_edb_on;				//外部数据总线占用时无法触发任何运算
	reg require_error,bus_crash,space_error;				//请求错误状态，总线冲突，运算数据个数超过了内部ram的空间
																		//               01为累加模式 00为单次加法
					//bit  6            5           4         3          2          1        0 
	assign state = {edb_busy,require_error,space_error,bus_crash,mult_busy,adder_busy,mac_finish};
//require_error:请求错误，如果申请的运算器正在工作则返回该错误
//space_error:如果累加或乘累加模式下，输入数据长度长于内部RAM规定长度，则返回该错误
//bus_crash:如果
//控制器参数定义
	//顶层控制器参数(协调加法器、乘法器、判断模式、实现加法器与乘法器的并行运行)
	//
	reg mac_start;								//乘累加运算开启
	reg [12:0]mac_loop;

	//底层控制器参数(加法器、乘法器及RAM控制)
	reg[4:0] state_m,state_a;					//状态机
	
//流水线信号延迟三个时钟输出缓存
reg mult_wen_delay[2:0];
reg mult_ram_wen;
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~//
//~~~~~~~~~~~~~~功     能     实     现     部     分~~~~~~~~~~~~~~~~~//
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~//
//开始信号上升沿判断缓冲、流水线延时（三级流水线，3个时钟后延时输出信号，读取不延时）
always @(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		ss_pedge_buf <= 1;
	end
	else begin
		ss_pedge_buf <= ctrl[0];
		
		mult_wen_delay[2] <= mult_wen_delay[1];
		mult_wen_delay[1] <= mult_wen_delay[0];
		mult_wen_delay[0] <= mult_ram_wen;
	end
end

//中央控制区域：并行调用运算单元，传递各运算单元触发信息，error信号生成
always @(posedge clk or negedge rst_n) begin
	if(!rst_n)begin
		mac_start <= 0;
		require_error <= 0;
		bus_crash <= 0;
		space_error <= 0;
	end
	else begin
		if(start_signal == 1)begin								//接收到触发信号
			require_error <= 0;
			bus_crash <= 0;
			space_error <= 0;
			if(adder_busy|mult_busy == 1) begin
				require_error <= 1;
			end
			else if(edb_busy == 1) begin
				bus_crash <= 1;
			end
			else begin
				mac_start <= 1;
				mac_loop <= ctrl_loop;
			end
		end
		else begin														//未接收到触发信号
			mac_start <= 0;
		end
	end
end

//乘累加器控制部分
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin				//初始化
		mult_enable <= 0;
		mult_addr_rd <= 0;
		mult_busy <= 0;
		mult_edb_on <= 0;
		mult_ram_wen <= 0;
		
		adder_enable <= 0;					//加法器使能
		adder_busy <= 0;
		acc_start <= 0;
		
		mac_finish <= 1;
		
		state_m <= 0;
	end
	else begin
		case(state_m)
		0:begin												//乘法器等待状态
			if(mac_start)begin							//乘法器接收到工作信号，开始工作
				mult_enable <= 1;							//使能乘法器时钟
				mult_addr_rd <= 0;						//输入地址为0
				mult_ram_wen <= 0;						//写使能
				mult_busy <= 1;							//置位工作状态指示位
				mult_edb_on <= 1;							//置位乘法器数据占用
				
				adder_enable <= 1;
				adder_busy <= 1;							//加法器置位运行状态
				adder_rst <= 0;
				acc_start <= 0;
				
				mac_finish <= 0;							//开启运算
				state_m <= 1;								//进入运算状态
			end
			else begin										//等待开始信号
				
				state_m <= 0;								//未接受到开始信号，进入等待状态
			end
		end
		1:state_m <= 2;									//等待复位与时钟稳定
		2:begin
			adder_rst <= 1;
			state_m <= 4;
		end
		4:begin												//读第0个地址，写第0个地址，写使能
			mult_ram_wen <= 1;
			state_m <= 5;
		end
		5:begin												//依次运算
			if(mult_addr_rd < mac_loop)begin
				mult_addr_rd <= mult_addr_rd+1'b1;
				mult_ram_wen <= 1;						//写使能
				state_m <= 5;
			end
			else begin
				mult_ram_wen <= 0;
				mult_edb_on <= 0;								//释放外部数据总线
				state_m <= 6;
			end
		end
		6:state_m <= 7;									//延时三个时钟
		7:state_m <= 9;
		
		9:begin												//运算完成，结束运算
			mult_enable <= 0;								//关闭乘法器时钟
			acc_start <= 1;
			state_m <= 10;
		end
		10:begin												//运算完成，进入等待状态
			mult_busy <= 0;
			acc_start <= 0;
			state_m <= 11;
		end
		11:begin
			if(acc_finish)begin
				adder_enable <= 0;
				adder_busy <= 0;
				mac_finish <= 1;
				state_m <= 12;
			end
			else begin
				state_m <= 11;
			end
		end
		default: state_m <= 0;
		endcase
	end
end
endmodule
 