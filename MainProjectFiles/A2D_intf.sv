module A2D_intf(clk, rst_n, strt_cnv, cnv_cmplt, chnnl, res, SS_n, SCLK, MOSI, MISO);

input clk, rst_n, strt_cnv;
input logic MISO;
output reg cnv_cmplt;
output reg SS_n, SCLK, MOSI;
input [2:0]chnnl;
output [11:0]res;

logic snd;
logic [15:0]cmd;
logic done;	//output of SPI
logic [15:0]resp;	//output of SPI

SPI_mnrch SPI_transaction(.clk(clk), .rst_n(rst_n), .MISO(MISO), .snd(snd), .cmd(cmd), .SS_n(SS_n), .SCLK(SCLK), .MOSI(MOSI), .done(done), .resp(resp));

/////////////////////////////////////////////
// use the channel to send a signal to cmd //
/////////////////////////////////////////////
assign cmd = {2'b00,chnnl,11'h000};

// intermediate value for the state machine, used to determine when to assert cnv_cmplt
logic set_cnv_cmplt;

// 12-bit result from A2D, lower 12 bits of the read from SPI
assign res = resp[11:0];

typedef enum reg [1:0] {IDLE, CHNNL_CNV, WAITCLK, DONE} state_t;
state_t state, nxt_state;

/////////////////////////////////////////////////////////
//Sends a command to the A2D via SPI to ask for  a    //
//conversion on channel, then waits a clock cycle    //
//It then starts a new transaction to read the      //
//result of the A2D conversoin back. Then waits    //
//for it to be done to start a new read.	  //
///////////////////////////////////////////////////			
always_ff @(posedge clk, negedge rst_n) begin
  if (!rst_n)
    state <= IDLE;
  else
    state <= nxt_state;
end

always_comb begin
nxt_state = state;
snd = 1'b0;
set_cnv_cmplt = 1'b0;

  case(state)
    // IDLE: wait for signal to start, then send the command
    default : if (strt_cnv) begin
	    snd = 1'b1;
	    nxt_state = CHNNL_CNV;
	  end
    // once conversion 1 is done, start second conversion
    CHNNL_CNV : if (done) begin
	     nxt_state = WAITCLK;
	   end
    // need to wait a clock cycle for data, then send the next command
    WAITCLK : begin
	     snd = 1'b1;
	     nxt_state = DONE;
           end
    // wait for conversion two, then assert the complete signal and go back to IDLE state
    DONE : if (done) begin
	    set_cnv_cmplt = 1'b1;
	    nxt_state = IDLE;
          end
  endcase
end

////////////////////////////////////////////
//detects when the conversion is complete //
////////////////////////////////////////////
always_ff @(posedge clk, negedge rst_n) begin
  if (!rst_n)
    cnv_cmplt <= 1'b0;
  else if (strt_cnv)
    cnv_cmplt <= 1'b0;
  else if (set_cnv_cmplt)
    cnv_cmplt <= 1'b1;
end


endmodule
