module I2S_Serf(clk, rst_n, I2S_sclk, I2S_ws, I2S_data, lft_chnnl, rght_chnnl, vld);

input clk, rst_n;
input I2S_sclk, I2S_ws, I2S_data;
output [23:0] lft_chnnl, rght_chnnl;
output logic vld;

// Intermediate signals
logic [4:0] bit_cntr;
logic eq22, eq23, eq24;
logic [47:0] shft_reg;
logic sclk_rise, clr_cnt;
logic sclk_q1, sclk_q2, sclk_q3;
logic ws_q1, ws_q2, ws_q3;

//////////////////////////
// Flop for bit counter //
//////////////////////////
always_ff @(posedge clk, negedge rst_n) begin
  if (!rst_n)
    bit_cntr <= 5'b00000;
  else if (clr_cnt)
    bit_cntr <= 5'b00000;
  else if (sclk_rise)
    bit_cntr <= bit_cntr + 1;
end

/////////////////////////////////////
// Decoding outputs of bit counter //
/////////////////////////////////////
assign eq22 = (bit_cntr == 5'b10110);	// Used to check if sclk is immediately low
assign eq23 = (bit_cntr == 5'b10111);	// Used to check if sclk is still high
assign eq24 = (bit_cntr == 5'b11000);	// Shift from left to right or right back to left

/////////////////////////////////////////////////
// Shift register; sample the data by shifting //
// when a rise on SCLK is detected.	       //	
/////////////////////////////////////////////////
always_ff @(posedge clk, negedge rst_n) begin
  if (!rst_n)
    shft_reg <= 48'h000000000000;
  else if (sclk_rise)
    shft_reg <= {shft_reg[46:0],I2S_data};
end
	
assign lft_chnnl = shft_reg[47:24];
assign rght_chnnl = shft_reg[23:0];

//////////////////////////////////////
// Synchronizer for I2S SCLK signal //
//////////////////////////////////////
always_ff @(posedge clk, negedge rst_n) begin
  if (!rst_n) begin
    sclk_q1 <= 1'b0;
    sclk_q2 <= 1'b0;
    sclk_q3 <= 1'b0;
  end
  else begin
    sclk_q1 <= I2S_sclk;
    sclk_q2 <= sclk_q1;
    sclk_q3 <= sclk_q2;
  end
end

// Rising edge detect for SCLK
assign sclk_rise = sclk_q2 & ~sclk_q3;


////////////////////////////////////
// Synchronizer for I2S WS signal //
////////////////////////////////////
always_ff @(posedge clk, negedge rst_n) begin
  if (!rst_n) begin
    ws_q1 <= 1'b0;
    ws_q2 <= 1'b0;
    ws_q3 <= 1'b0;
  end
  else begin
    ws_q1 <= I2S_ws;
    ws_q2 <= ws_q1;
    ws_q3 <= ws_q2;
  end
end

// Detects falling edge for WS
assign ws_fall = ~ws_q2 & ws_q3;


// State Machine to control the Serf and sample data
typedef enum reg [1:0] {IDLE, WAIT, LFT, RGHT} state_t;

state_t state,nxt_state;

always_ff @(posedge clk, negedge rst_n) begin
  if (!rst_n)
    state <= IDLE;
  else
    state <= nxt_state;
end

always_comb begin
nxt_state = state;
clr_cnt = 1'b0;
vld = 1'b0;

  case (state)
    default : begin	// IDLE is default state
	if (ws_fall) begin
	  nxt_state = WAIT;
	end
    end
    WAIT : begin	// Wait for SCLK to assert
	if (sclk_rise) begin
	  clr_cnt = 1'b1;
	  nxt_state = LFT;
	end
    end
    LFT : begin		// Decides to shift data left
	if (eq24) begin
	  clr_cnt = 1'b1;
	  nxt_state = RGHT;
	end
    end
    RGHT : begin	// Checks if result is valid
	if (eq22 && !I2S_ws) begin
	  nxt_state = IDLE;
	end
	else if (eq23 && I2S_ws && sclk_rise) begin
	  nxt_state = IDLE;
	end
	else if (eq24) begin
	  vld = 1'b1;
	  clr_cnt = 1'b1;
	  nxt_state = LFT;
	end
    end
  endcase
end



endmodule
