module FIR_B1(lft_out, rght_out, clk, rst_n, lft_in, rght_in, sequencing);

input clk, rst_n, sequencing;
input signed [15:0] rght_in, lft_in;
output [15:0] lft_out, rght_out;

logic [9:0] addr;
logic signed [15:0] dout;
logic inc_addr, clr_addr, clr_accum;
logic accum;
logic signed [31:0] lft_out_ff, rght_out_ff;

////////////////////////////
// Instantiate ROM for B1 //
////////////////////////////
ROM_B1 rom(.clk(clk), .addr(addr), .dout(dout));

///////////////////////////////////////////////
// Generates address for the Coefficient ROM //
///////////////////////////////////////////////
always_ff @ (posedge clk, negedge rst_n) begin
  if (!rst_n)
    addr <= 10'h000;
  else if (clr_addr)
    addr <= 10'h000;
  else if (inc_addr)
    addr <= addr + 1;
end

///////////////////////////////////////////////////////////////////////////////
// Left out flop which implements a mutiply-accumulate (MAC) for convolution //
///////////////////////////////////////////////////////////////////////////////
always_ff @ (posedge clk, negedge rst_n) begin
  if (!rst_n)
    lft_out_ff <= '0;
  else if (clr_accum)
    lft_out_ff <= '0;
  else if (accum)
    lft_out_ff <= (lft_in * dout) + lft_out_ff;
end
// Left out data uses the upper 16 bits of the convolution.
assign lft_out = lft_out_ff[30:15];

////////////////////////////////////////////////////////////////////////////////
// Right out flop which implements a mutiply-accumulate (MAC) for convolution //
////////////////////////////////////////////////////////////////////////////////
always_ff @ (posedge clk, negedge rst_n) begin
  if (!rst_n)
    rght_out_ff <= '0;
  else if (clr_accum)
    rght_out_ff <= '0;
  else if (accum)
    rght_out_ff <= (rght_in * dout) + rght_out_ff;
end
// Right out data uses the upper 16 bits of the convolution.
assign rght_out = rght_out_ff[30:15];

/////////////////////////
// State Machine Logic //
/////////////////////////
typedef enum reg {IDLE, CONV} state_t;
state_t state, nxt_state;

//////////////////////////////////
// Infer state/next state logic //
//////////////////////////////////
always_ff @(posedge clk, negedge rst_n) begin
  if (!rst_n)
    state <= IDLE;
  else
    state <= nxt_state;
end

always_comb begin
// Default outputs
nxt_state = state;
inc_addr = 1'b0;
clr_accum = 1'b0;
clr_addr = 1'b0;
accum = 1'b0;

  case (state)
    ////////////////////////////////////////////////////////////////////////////
    // IDLE: Waits for sequencing to be asserted, then increments the address //
    // and starts convolution. If staying in idle, the address is cleared.    //
    ////////////////////////////////////////////////////////////////////////////
    default : begin
      if (sequencing) begin
	clr_accum = 1'b1;
	inc_addr = 1'b1;
	nxt_state = CONV;
      end else begin
	clr_addr = 1'b1;
      end
    end
    //////////////////////////////////////////////////////////////////////////////////
    // Convolution: increments address. If sequencing goes low (i.e. done), go back //
    // to beginning. Otherwise, keep accumulating.				    //
    //////////////////////////////////////////////////////////////////////////////////
    CONV : begin
	inc_addr = 1'b1;
      if (!sequencing) begin
	nxt_state = IDLE;
      end else begin
	accum = 1'b1;
      end
    end

endcase
end



endmodule
