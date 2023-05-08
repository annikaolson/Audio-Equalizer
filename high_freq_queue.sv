module high_freq_queue(clk, rst_n, lft_smpl, rght_smpl, wrt_smpl, lft_out, rght_out, sequencing);

input clk, rst_n;
input logic [15:0] lft_smpl, rght_smpl;	// newest sample from I2S_Serf to be written into queue
input logic wrt_smpl;	// if high, write a sample then start a readout of 1021 samples from oldest to oldest + 1020. every other vld.
output logic [15:0] lft_out, rght_out;	// once queues are full, a readout of 1021 samples (starting w/ oldest) will be initiated every wrto_smpl
					// lft/rght_out is the data being read out
output logic sequencing;	// this signal is high the whole time the 1021 samples are being read out from the queue
				// essentially, this is the time the FIR filters would be calculating

logic [10:0] old_ptr, new_ptr, read_ptr, end_ptr;
logic full;
logic inc_read; // to advance the read pointer
logic done_read; // detects when read pointer equals old pointer + 1020

// Left DP RAM
dualPort1536x16 dualPortleft(.clk(clk), .we(wrt_smpl), .waddr(new_ptr), .raddr(read_ptr), .wdata(lft_smpl), .rdata(lft_out));
// Right DP RAM
dualPort1536x16 dualPortright(.clk(clk), .we(wrt_smpl), .waddr(new_ptr), .raddr(read_ptr), .wdata(rght_smpl), .rdata(rght_out));

// State machine logic:
typedef enum reg [1:0] {IDLE, SEQUENCING} state_t;
state_t state, nxt_state;

always_ff @ (posedge clk, negedge rst_n) begin
  if (!rst_n)
    state <= IDLE;
  else
    state <= nxt_state;
end

always_comb begin
// Default outputs
nxt_state = state;
sequencing = 1'b0;

  case (state)
    // Waits for the queue to be full and for write to be asserted
    default : begin
      if (full && wrt_smpl) begin
	nxt_state = SEQUENCING;
      end
    end
    // Sequencing state to read the data
    SEQUENCING: begin
	sequencing = 1'b1;
      if (done_read) begin	// Once queue is full, old pointer and new pointer increment together. 
	nxt_state = IDLE;
      end
    end
  endcase
end


// Here we are detecting when the queue is full, which is now when the new pointer is 1531
always_ff @ (posedge clk, negedge rst_n) begin
  if (!rst_n)
    full <= 1'b0;
  else if (new_ptr == 11'd1531)
    full <= 1'b1;
end

//////////////////////////////////////////////////////////////////////////////////////////
// the easiest case is when read pointer can be assigned the same as in low frequency,  //
// otherwise we must account for the wrap around.					//
//////////////////////////////////////////////////////////////////////////////////////////
assign done_read = (old_ptr < 516) ? (read_ptr == (old_ptr + 10'd1020)) : (read_ptr == old_ptr - 10'd516);

// New pointer counter
always_ff @ (posedge clk, negedge rst_n) begin
  if (!rst_n)
    new_ptr <= '0;
  else if (wrt_smpl && new_ptr == 11'd1535)
    new_ptr <= '0;
  else if (wrt_smpl)
    new_ptr <= new_ptr + 1;
end

// Old pointer counter, must wrap around to 0 once it hits 1535
always_ff @ (posedge clk, negedge rst_n) begin
  if (!rst_n)
    old_ptr <= '0;
  else if (wrt_smpl && full && old_ptr == 11'd1535)
    old_ptr <= '0;
  else if (wrt_smpl && full)
    old_ptr <= old_ptr + 1;
end

// Read pointer counter
always_ff @ (posedge clk) begin
  if (wrt_smpl && full)
    read_ptr <= old_ptr;
  else if (sequencing && read_ptr == 11'd1535)
    read_ptr <= '0;
  else if (sequencing)
    read_ptr <= read_ptr + 1;
end


endmodule
