module SPI_mnrch(clk, rst_n, MISO, snd, cmd, SS_n, SCLK, MOSI, done, resp);

input clk, rst_n, snd, MISO;
input [15:0]cmd;
output reg done, SS_n, SCLK, MOSI;
output [15:0]resp;

// intermediate signals for bit counter
logic [4:0]bit_cntr;
logic done16;
// intermediate signals for sclk_div counter
logic [4:0]SCLK_div;
// output for shifter mux
logic [15:0]shft_reg;
// intermediate signals for SM
logic init, ld_SCLK, shft, full, set_done;

//Bit Counter - counts how many times we have shifted, up to 16.//
//this keeps track of how many times the shift register has shifted.//
always_ff @(posedge clk, negedge rst_n) begin
  if (!rst_n)
    bit_cntr <= 5'b00000;
  else if (init)
    bit_cntr <= 5'b00000;
  else if (shft)
    bit_cntr <= bit_cntr + 1;
end

assign done16 = bit_cntr[4];

//Counts the SCLK_div. This asserts the shift signal after two system//
//clocks after the rise of SCLK to avoid timing difficulties.//
always_ff @(posedge clk, negedge rst_n) begin
  if (!rst_n)
    SCLK_div <=  5'b00000;
  else if (ld_SCLK)
    SCLK_div <= 5'b10111;
  else
    SCLK_div <= SCLK_div + 1;
end

assign SCLK = SCLK_div[4];
assign full = &SCLK_div;
assign shft = SCLK_div == 5'b10001;

//This shift register produces MOSI as the new MSB, and it takes in MISO//
//as the new LSB. This shift register can be parallel laoded with//
//data to send (cmd), left shift one position, or keep the same value.//
always_ff @(posedge clk, negedge rst_n) begin
  if (!rst_n)
    shft_reg <= 16'h0000;
  else if (init)
    shft_reg <= cmd;
  else if (shft)
    shft_reg <= {shft_reg[14:0], MISO};
end
	
assign MOSI = shft_reg[15]; 
assign resp = shft_reg;     

//State machine to control the done signal and sends the proper signals//
//to execute the SPI implementation//
typedef enum reg [1:0] {IDLE, SHIFT, DONE} state_t;
state_t state, nxt_state;

always_ff @(posedge clk, negedge rst_n) begin
  if (!rst_n)
	state <= IDLE;
  else
	state <= nxt_state;
end

always_comb begin
//default all to avoid unintended latches
  nxt_state = IDLE;
  init = 1'b0;
  ld_SCLK = 1'b1;
  set_done = 1'b0;

  case(state)
	// Waits for the send command, then asserts initialize signal
	IDLE : if (snd) begin
		  init = 1'b1;
	 	  ld_SCLK = 1'b0;
		  nxt_state = SHIFT;
		end
  
	// waits for the 16-bit counter to be full to be done
	SHIFT : if (done16) begin
		  nxt_state = DONE;
		end
		else begin
		  ld_SCLK = 1'b0;
		  nxt_state = SHIFT;
		end
	
	// waits for the 16-bit counter to be full to be done
	 DONE : if (full) begin
		  set_done = 1'b1;
		  nxt_state = IDLE;
		end
		else begin
		  nxt_state = DONE;
		  ld_SCLK = 1'b0;
			end
	
	// Default state is IDLE
	default : begin
		  nxt_state = IDLE;
		  init = 0;
 		  ld_SCLK = 1;
 		  set_done = 0;
		end
  endcase
end


/////////////////////////////////////////////////
//Register to produce the SS_n and done signal //
/////////////////////////////////////////////////
always_ff @(posedge clk, negedge rst_n) begin
  if (!rst_n) begin
	SS_n <= 1'b1;
	done <= 1'b0;
	end
  else if (set_done) begin
	SS_n <= 1'b1;
	done <= 1'b1;
  	end
  else if (init) begin
	SS_n <= 1'b0;
	done <= 1'b0;
	end
end


endmodule
