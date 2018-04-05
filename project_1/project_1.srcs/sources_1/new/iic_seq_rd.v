module iic_seq_rd(
	input clk,
	input rst_n,
	input req,
	output ready,
	output reg rd_ack,
	input scl_i,
	inout sda,
	input [12:0] addr,
	output reg [7:0] dout

);
reg sda_r;
reg sda_link;
assign sda=sda_link?sda_r:1'hz;

reg [12:0] addr_r;
reg [5:0] state;
reg [3:0] counter;
reg [7:0] rd_data;

parameter IDLE=6'd0,
			 START1=6'd1,
			 RDCB1=6'd2,
			 RDCB1ACK=6'd3,
			 ADDRH=6'd4,
			 ADDRHACK=6'd5,
			 ADDRL=6'd6,
			 ADDRLACK=6'd7,
			 START2=6'd8,
			 RDCB2=6'd9,
			 RDCB2ACK=6'd10,
			 DATA=6'd11,
			 NOACK=6'd12,
			 STOP=6'd13;
			 
always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		addr_r<=0;
	else if(req)
		addr_r<=addr;
end

always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)begin
		rd_ack<=0;
		dout<=0;end
	else if((state==NOACK)&scl_i)begin
		rd_ack<=1;
		dout<=rd_data;end
	else begin
		rd_ack<=0;
		dout<=dout;end
end
//-----------------------------
`define JumpH scl_i//宏定义不加分号
`define JumpL ~scl_i
reg [5:0] cnt;
always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)begin
		state<=IDLE;
		cnt<=0;end
	else case(state)
			IDLE:if(req)
					state<=START1;
			START1:if(`JumpH)
						state<=RDCB1;
			RDCB1:if(`JumpL)
						if(counter==4'd8)
							begin
							state<=RDCB1ACK;
							counter<=0;
							end
						else
							counter<=counter+1;
			RDCB1ACK:if((sda==0)&&`JumpH)
							state<=ADDRH;
						else 
							state<=IDLE;
			ADDRH:if(`JumpL)
						if(counter==4'd8)
							begin
							state<=ADDRHACK;
							counter<=0;
							end
						else
							counter<=counter+1;
			ADDRHACK:if((sda==0)&&`JumpH)
							state<=ADDRL;
						else 
							state<=IDLE;
			ADDRL:if(`JumpL)
						if(counter==4'd8)
							begin
							state<=ADDRLACK;
							counter<=0;
							end
						else
							counter<=counter+1;
		   ADDRLACK:if((sda==0)&&`JumpH)
							state<=START2;
						else 
							state<=IDLE;
			START2:begin
						state<=RDCB2;
						end
			RDCB2:if(`JumpL)
						if(counter==4'd8)
							begin
							state<=RDCB2ACK;
							counter<=0;
							end
						else
							counter<=counter+1;
			RDCB2ACK:if((sda==0)&&`JumpH)
							state<=DATA;
						else 
							state<=IDLE;
			DATA:if(`JumpL)begin
						if(counter==4'd7)
							begin
							state<=NOACK;
							counter<=0;
							end
						else
							counter<=counter+1;
					end
			NOACK:if(`JumpH)
						if(cnt<31)begin
							cnt<=cnt+1;
							state<=DATA;end
						else begin
							cnt<=0;
							state<=STOP;end
			STOP:if(`JumpH)
						state<=IDLE;
			default:state<=IDLE;
			endcase
end

always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		begin
		sda_link<=1;
		sda_r<=1;
		end
	else	case(state)
			START1:if(~scl_i)
						begin
							sda_link<=1;
							sda_r<=1;
						end
					else begin
							sda_link<=1;
							sda_r<=0;
							end
			START2:if(~scl_i)
						begin
							sda_link<=1;
							sda_r<=1;
						end
					else begin
							sda_link<=1;
							sda_r<=0;
							end
			RDCB1:if(~scl_i)
						case(counter)
							4'd0:begin sda_r<=1'b1; sda_link<=1; end
							4'd1:begin sda_r<=1'b0; sda_link<=1; end 
							4'd2:begin sda_r<=1'b1; sda_link<=1; end
							4'd3:begin sda_r<=1'b0; sda_link<=1; end
							4'd4:begin sda_r<=1'b0; sda_link<=1; end
							4'd5:begin sda_r<=1'b0; sda_link<=1; end 
							4'd6:begin sda_r<=1'b0; sda_link<=1; end
							4'd7:begin sda_r<=1'b0; sda_link<=1; end
							4'd8:begin sda_r<=1'bx; sda_link<=0; end
						endcase
			ADDRH:if(~scl_i)
						case(counter)
							4'd0:begin sda_r<=1'b0; sda_link<=1; end
							4'd1:begin sda_r<=1'b0; sda_link<=1; end 
							4'd2:begin sda_r<=1'b0; sda_link<=1; end
							4'd3:begin sda_r<=addr_r[12]; sda_link<=1; end
							4'd4:begin sda_r<=addr_r[11]; sda_link<=1; end
							4'd5:begin sda_r<=addr_r[10]; sda_link<=1; end 
							4'd6:begin sda_r<=addr_r[9]; sda_link<=1; end
							4'd7:begin sda_r<=addr_r[8]; sda_link<=1; end
							4'd8:begin sda_r<=1'bx; sda_link<=0; end
						
						endcase
			ADDRL:if(~scl_i)
						case(counter)
							4'd0:begin sda_r<=addr_r[7]; sda_link<=1; end
							4'd1:begin sda_r<=addr_r[6]; sda_link<=1; end 
							4'd2:begin sda_r<=addr_r[5]; sda_link<=1; end
							4'd3:begin sda_r<=addr_r[4]; sda_link<=1; end
							4'd4:begin sda_r<=addr_r[3]; sda_link<=1; end
							4'd5:begin sda_r<=addr_r[2]; sda_link<=1; end 
							4'd6:begin sda_r<=addr_r[1]; sda_link<=1; end
							4'd7:begin sda_r<=addr_r[0]; sda_link<=1; end
							4'd8:begin sda_r<=1'bx; sda_link<=0; end
						
						endcase
				endcase
end
endmodule
