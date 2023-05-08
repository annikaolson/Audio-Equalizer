module low_freq_queue(clk, rst_n, lft_smpl, rght_smpl, wrt_smpl, lft_out, rght_out, sequencing);

input clk, rst_n;
input logic [15:0] lft_smpl, rght_smpl;	// newest sample from I2S_Serf to be written into queue
input logic wrt_smpl;	// if high, write a sample then start a readout of 1021 samples from oldest to oldest + 1020. every other vld.
output logic [15:0] lft_out, rght_out;	// once queues are full, a readout of 1021 samples (starting w/ oldest) will be initiated every wrto_smpl
					// lft/rght_out is the data being read out
output logic sequencing;	// this signal is high the whole time the 1021 samples are being read out from the queue
				// essentially, this is the time the FIR filters would be calculating

logic [9:0] old_ptr, new_ptr, read_ptr, end_ptr;
logic full;
logic done_read; // detects when read pointer equals old pointer + 1020

// Left DP RAM
dualPort1024x16 dualPortleft(.clk(clk), .we(wrt_smpl), .waddr(new_ptr), .raddr(read_ptr), .wdata(lft_smpl), .rdata(lft_out));
// Right DP RAM
dualPort1024x16 dualPortright(.clk(clk), .we(wrt_smpl), .waddr(new_ptr), .raddr(read_ptr), .wdata(rght_smpl), .rdata(rght_out));

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


// Old pointer starts at 0, and stays there until the queue is full. Here we are detecting when the queue is full.
always_ff @ (posedge clk, negedge rst_n) begin
  if (!rst_n)
    full <= 1'b0;
  else if (new_ptr == 10'd1021)
    full <= 1'b1;
end

// Detects when the we are done reading
assign done_read = (read_ptr == (old_ptr + 10'd1020));

// Incrememnter for new pointer, increments every pos edge of write being asserted
always_ff @ (posedge clk, negedge rst_n) begin
  if (!rst_n) begin
    new_ptr <= '0;
  end
  else if (wrt_smpl) begin
    new_ptr <= new_ptr + 1;
  end
end

// Incrementer for old pointer, increments when full and write is asserted
always_ff @ (posedge clk, negedge rst_n) begin
  if (!rst_n) begin
    old_ptr <= '0;
  end
  else if (wrt_smpl && full) begin
    old_ptr <= old_ptr + 1;
  end
end

// Incrememnter for read pointer, initializes to old pointer then increments when we are sequencing
always_ff @ (posedge clk) begin
  if (wrt_smpl && full) begin
    read_ptr <= old_ptr;
  end
  else if (sequencing) begin
    read_ptr <= read_ptr + 1;
  end
end


endmodule





