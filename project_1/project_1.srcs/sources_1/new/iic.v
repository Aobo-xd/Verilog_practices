module iic(
	input clk,
	input rdt_n,
	
	output ready,
	input req,
	input cs_n,
	output rd_ack,
	output wr_ack,
	input  [7:0] addr,
	input  [7:0] din,
	output reg [7:0] dout,
	
	output scl,
	inout sda 
);

//产生scl时钟//
reg  scl_r;
always @(negedge clk or negedge rst_n)
begin
	if(!rst_n)
		scl_r<=0;
	else 
		scl_r<=~scl_r;
end
assign scl =scl_r;
//输入req和cs_n决定是哪一种模式//
reg [3:0] mood;
always @(posedge clk or negedge rst_n)begin
	if(!rst_n)
		mood<=4'd0;
	//error:else case(req,cs_n[3:0])
	else case({req,cs_n[3:0]})
		5'b1_0001:mood<=4'b0001;//type_wr
		5'b1_0010:mood<=4'b0010;//seq_wr
		5'b1_0100:mood<=4'b0100;//random_rd
		5'b1_1000:mood<=4'b1000;//req_rd
		default:mood<=mood;
	endcase
end

//根据模式对ready，ack等进行赋值//
wire ready0,ready1,ready2,ready3;
wire wr_ack0,wr_ack1,rd_ack0,rd_ack1;
assign ready=~(ready0&ready1&ready2);


endmodule 
