module BT_intf(next_n, prev_n, clk, rst_n, cmd_n, TX, RX);
  input next_n, prev_n, clk, rst_n, RX;
  output logic TX, cmd_n;

// Intermediate signals //
logic next, prev, send, resp_rcvd;
logic [4:0] cmd_start;
logic [3:0] cmd_len;
logic [17:0] cntr;

//////////////////////////////////////////////////////////////
// Instantiate PB_release for the next and previous buttons //
//////////////////////////////////////////////////////////////
PB_release iDUTn(.PB(next_n), .rst_n(rst_n), .clk(clk), .released(next));
PB_release iDUTp(.PB(prev_n), .rst_n(rst_n), .clk(clk), .released(prev));

// Instantiate snd_cmd
snd_cmd iDUT0(.clk(clk), .rst_n(rst_n), .cmd_start(cmd_start), .send(send), .cmd_len(cmd_len), .resp_rcvd(resp_rcvd), .TX(TX), .RX(RX));

/////////////////////////////////////////////////////////////////////////////
// 17-bit Counter to detect when to move to the first initialization state //
/////////////////////////////////////////////////////////////////////////////
always_ff @(posedge clk, negedge rst_n) begin
  if (!rst_n) 			cntr <= 18'h00000;
  else if (cntr <= 18'h1FFFF) 	cntr <= cntr + 1; end

/////////////////////////
// State Machine logic //
/////////////////////////
typedef enum reg [2:0] {RESET, INIT1, INIT2, WAIT, SND_CMD} state_t; 
state_t state, nxt_state;

// Infer state flops //
always_ff @(posedge clk, negedge rst_n) begin
  if (!rst_n)
    state <= RESET;
  else
    state <= nxt_state; end

always_comb begin
// default all to avoid latches
  nxt_state = state;
  cmd_n = 1'b0;
  send = 1'b0;

case (state)
  // RESET: assert the command to send
  default: begin
    cmd_n = 1'b1; 
    if (cntr == 18'h1FFFF) begin
      nxt_state = INIT1; end
  end
  /////////////////////////////////////////////////////////////////
  // wait for the response to be received, then send the address //
  // and length of the first command, and assert send.		 //
  /////////////////////////////////////////////////////////////////
  INIT1: begin
    if (resp_rcvd) begin
      cmd_start = 5'b00000;
      cmd_len = 4'b0110;
      send = 1'b1;
      nxt_state = INIT2; end
  end
  //////////////////////////////////////////////////////////////////////
  // wait for the response of the first command to be received, then  //
  // send the address and length of the second command. assert send.  //
  //////////////////////////////////////////////////////////////////////
  INIT2: begin
   if (resp_rcvd) begin
      cmd_start = 5'b00110;
      cmd_len = 4'b1010;
      send = 1'b1;
      nxt_state = WAIT; end
  end
  // Need to wait one clock cycle for data to be properly sent.
  WAIT: begin
    if (resp_rcvd) begin
      nxt_state = SND_CMD; end
    end
  //////////////////////////////////////////////////////////////////////////////////////
  // Detects the next or previous button, and sends the associated command with each. //
  // This moves to either the next or previous song, respectively. 		      //
  //////////////////////////////////////////////////////////////////////////////////////
  SND_CMD: begin
    if (next) begin
      cmd_start = 5'b10000;
      cmd_len = 4'b0100; 
      send = 1'b1; end

    if (prev) begin
      cmd_start = 5'b10100;
      cmd_len = 4'b0100; 
      send = 1'b1; end 
  end
 endcase
end 

endmodule
 