module iic_type_wr
(
	input clk,
	input rst_n,
	input req,
	output ready,
	input [12:0] addr,
	input [7:0] din,
	output reg wr_ack,
	input scl_i,
	inout sda

);
//本代码中为状态机一段式，只是分开成了两个always模块。
//二段式状态机是第一个时序逻辑为状态寄存，第二个组合逻辑为状态跳转和赋值
//三段式状态机是第一个时序逻辑为状态寄存，第二个组合逻辑为状态跳转，第三个组合逻辑为赋值
reg sda_link,sda_r;
reg [4:0] state;
reg [7:0] wr_data;
reg [12:0] addr_r;
assign sda=sda_link?sda_r:1'dz;
parameter IDLE=5'd0,
			 START=5'd1,
			 WRCB=5'd2,
			 WRCBACK=5'd3,
			 ADDH=5'd4,
			 ADDHACK=5'd5,
			 ADDL=5'd6,
			 ADDLACK=5'd7,
			 DATA=5'd8,
			 DATAACK=5'd9,
			 STOP=5'd10;
//---------------------------------

reg [3:0] counter;			 
always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		begin
		wr_ack<=0;
		wr_data<=0;
		addr_r<=0;
		end
	else begin
		
		if((state==DATA)&(counter==4'd7)&(~scl_i))
			wr_ack<=1;
		else
			wr_ack<=0;
			
		if(req)
			wr_data<= din;
		if(req)
			addr_r<=addr;
		end
end

//-----------------------------

always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		state<=IDLE;
	else case(state)
			IDLE:begin
					if(req)
						state<=START;
				  end
			START:begin
					if(scl_i)
						state<=WRCB;
					end
			WRCB:begin
					if(~scl_i)
						if(counter==4'd8)
							begin
							state<=WRCBACK;
							counter<=0;
							end
						else
							counter<=counter+1;
					end
			WRCBACK:begin
						if((scl_i==1)&&(sda==0))
							state<=ADDH;
					  else 
							state<=IDLE;
						end
			ADDH:		begin
						if(~scl_i) 
							if(counter==4'd8)
								begin
								counter<=0;
								state<=ADDHACK;
								end
							else
								counter<=counter+1;
						end
			ADDHACK:begin
						if((scl_i==1)&&(sda==0))
							state<=ADDL;
						else
							state<=IDLE;
						end
			ADDL:begin
					if(~scl_i)
						if(counter==4'd8)
							begin
							state<=ADDLACK;
							counter<=0;
							end
						else
							counter<=counter+1;
					end
			ADDLACK:begin
						if((scl_i==1)&&(sda==0))
							state<=DATA;
						else
							state<=IDLE;
						end
			DATA:begin
					if(~scl_i)
						if(counter==4'd8)
							begin
							state<=DATAACK;
							counter<=0;
							end
						else
							counter<=counter+1;
					end
			DATAACK:begin
						if((scl_i==1)&&(sda==0))
							state<=STOP;
						else
							state<=IDLE;
						end
			STOP:begin
					if(scl_i)
						state<=IDLE;
					end
			default:state<=IDLE;
			endcase
end
always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		begin
		sda_link<=0;
		sda_r<=1;
		end
	else case(state)
		START:if(~scl_i)
					begin
						sda_link<=1;
						sda_r<=1;
					end
				else
					begin
						sda_link<=1;
						sda_r<=0;
					end
		WRCB:if(~scl_i)
					case(counter)
						4'd0:begin sda_r<=1;sda_link<=1; end
						4'd1:begin sda_r<=0;sda_link<=1; end
						4'd2:begin sda_r<=1;sda_link<=1; end
						4'd3:begin sda_r<=0;sda_link<=1; end
						4'd4:begin sda_r<=0;sda_link<=1; end
						4'd5:begin sda_r<=0;sda_link<=1; end
						4'd6:begin sda_r<=0;sda_link<=1; end
						4'd7:begin sda_r<=0;sda_link<=1; end
						4'd8:begin sda_r<=1'bx;sda_link<=0; end
						default:sda_r<=sda_r;
					endcase	
		ADDH:if(~scl_i)
					case(counter)
						4'd0:begin sda_r<=0;sda_link<=1; end
						4'd1:begin sda_r<=0;sda_link<=1; end
						4'd2:begin sda_r<=0;sda_link<=1; end
						4'd3:begin sda_r<=addr_r[12];sda_link<=1; end
						4'd4:begin sda_r<=addr_r[11];sda_link<=1; end
						4'd5:begin sda_r<=addr_r[10];sda_link<=1; end
						4'd6:begin sda_r<=addr_r[9];sda_link<=1; end
						4'd7:begin sda_r<=addr_r[8];sda_link<=1; end
						4'd8:begin sda_r<=1'bx;sda_link<=0; end
						default:sda_r<=sda_r;
					endcase
		ADDL:if(~scl_i)
					case(counter)
						4'd0:begin sda_r<=addr_r[7];sda_link<=1; end
						4'd1:begin sda_r<=addr_r[6];sda_link<=1; end
						4'd2:begin sda_r<=addr_r[5];sda_link<=1; end
						4'd3:begin sda_r<=addr_r[4];sda_link<=1; end
						4'd4:begin sda_r<=addr_r[3];sda_link<=1; end
						4'd5:begin sda_r<=addr_r[2];sda_link<=1; end
						4'd6:begin sda_r<=addr_r[1];sda_link<=1; end
						4'd7:begin sda_r<=addr_r[0];sda_link<=1; end
						4'd8:begin sda_r<=1'bx;sda_link<=0; end
						default:sda_r<=sda_r;
					endcase
		DATA:if(~scl_i)
					case(counter)
						4'd0:begin sda_r<=wr_data[7];sda_link<=1; end
						4'd1:begin sda_r<=wr_data[6];sda_link<=1; end
						4'd2:begin sda_r<=wr_data[5];sda_link<=1; end
						4'd3:begin sda_r<=wr_data[4];sda_link<=1; end
						4'd4:begin sda_r<=wr_data[3];sda_link<=1; end
						4'd5:begin sda_r<=wr_data[2];sda_link<=1; end
						4'd6:begin sda_r<=wr_data[1];sda_link<=1; end
						4'd7:begin sda_r<=wr_data[0];sda_link<=1; end
						4'd8:begin sda_r<=1'bx;sda_link<=0; end
						default:sda_r<=sda_r;
					endcase
		STOP:if(~scl_i)
					begin
					sda_link<=1;
					sda_r<=0;
					end
				else
					begin
					sda_link<=1;
					sda_r<=1;
					end
		default:begin
					sda_link<=0;
					sda_r<=0;
					end
		endcase
end
endmodule
