module snd_cmd(clk, rst_n, cmd_start, send, cmd_len, resp_rcvd, RX, TX);

input [4:0] cmd_start;	// Address of the command
input send;
input logic clk, rst_n;
input [3:0] cmd_len;	// Length of the command
output resp_rcvd; // Recieved response asserted from UART trasceiver
input logic RX;
output logic TX;

logic [4:0] addr;
logic [4:0] cmd_sum;
logic trmt, tx_done, rx_rdy;
logic [7:0] dout, tx_data, rx_data;
logic last_byte, inc_addr;

// Instantiate cmdROM and UART
cmdROM ROM(.clk(clk), .addr(addr), .dout(dout));
UART transciever(.clk(clk), .rst_n(rst_n), .RX(RX), .TX(TX), .trmt(trmt), .clr_rx_rdy(rx_rdy), .tx_data(tx_data), .rx_rdy(rx_rdy), .tx_done(tx_done), .rx_data(rx_data));

///////////////////////////////////////////////////////
// Register to control the address input to cmdROM.  //
// Increments the command's start value each time we //
// recognize that the last byte of the command has   //
// not yet been sent, until we reach the last byte.  //
///////////////////////////////////////////////////////
always_ff @(posedge clk, negedge rst_n) begin
  if (!rst_n)
    addr <= 5'b00000;
  else if (send)
    addr <= cmd_start;
  else if (inc_addr)
    addr <= addr + 1;
end

assign tx_data = dout;

////////////////////////////////////////////////////////////////
// Register to control last_byte input to state machine. When //
// the command is sent, the length and start value are added  //
// to determine the total number of the last byte that should //
// be sent; recirculates that value every clock cycle.        //
////////////////////////////////////////////////////////////////
always_ff @(posedge clk, negedge rst_n) begin
  if (!rst_n)
    cmd_sum <= 5'b00000;
  else if (send)
    cmd_sum <= cmd_len + cmd_start;
end

// Asserts this signal when the last byte has been sent
assign last_byte = (cmd_sum == addr);


// State Machine to control the transmission process for each byte
typedef enum reg [1:0] {IDLE, WAIT, TRNSMT, DONE} state_t;
state_t state,nxt_state;

always_ff @(posedge clk, negedge rst_n) begin
  if (!rst_n)
    state <= IDLE;
  else
    state <= nxt_state;
end

// State logic
always_comb begin
// Default next state and outputs
  nxt_state = state;
  trmt = 1'b0;
  inc_addr = 1'b0;

  case (state)
    // Default state is IDLE, waits for the signal to send the command
    default : begin
	if (send) begin
	  nxt_state = WAIT;
	end
    end
    // Wait for ROM to read the data, needs one clock cycle
    WAIT : begin	
	nxt_state = TRNSMT;    
    end
    // Transmits the data
    TRNSMT : begin
	trmt = 1'b1;
	inc_addr = 1'b1;
	nxt_state = DONE;
    end
    // Waits for the UART to send the byte, transmits again
    // if we have not reached the last byte of the command
    DONE : begin
	if (tx_done && !last_byte) begin
	  nxt_state = TRNSMT;
	end
	else if (tx_done && last_byte)
	  nxt_state = IDLE;
    end

  endcase
end

// The response has been recieved once the data equals x0A, as sent from the RN52 model.				    				
assign resp_rcvd = (rx_rdy && (rx_data == 8'h0A));  


endmodule



