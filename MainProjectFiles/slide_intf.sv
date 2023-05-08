module slide_intf(POT_LP, POT_B1, POT_B2, POT_B3, POT_HP, VOLUME, clk, rst_n, SS_n, SCLK, MOSI, MISO);

input clk, rst_n;
input logic MISO;
output logic SS_n, SCLK, MOSI;
output reg [11:0] POT_LP, POT_B1, POT_B2, POT_B3, POT_HP, VOLUME;

logic strt_cnv, cnv_cmplt;
logic [2:0] chnnl;
logic [11:0] res;

logic EN, jump;

// Instantiates A2D_intf
A2D_intf A2D(.clk(clk), .rst_n(rst_n), .strt_cnv(strt_cnv), .chnnl(chnnl), .MISO(MISO), .cnv_cmplt(cnv_cmplt), .res(res), .SS_n(SS_n), .SCLK(SCLK), .MOSI(MOSI));

// 3 bit counter to count to 8
always_ff @(posedge clk, negedge rst_n) begin
  if (!rst_n) begin
    chnnl <= 3'b000;
  end
  else if (EN && jump) begin
    chnnl <= 3'b111;
  end
  else if (EN) begin
    chnnl <= chnnl + 1;
  end
end

// jump to 7, as there is no channel 5 or 6.
assign jump = (chnnl == 3'b100);

// enable logic: enable from SM && bit_cntr = channel

// RRsequencer -> controls the conversion and increments the channel when needed
typedef enum reg [1:0] {STRT_CNV, CNV_CMPLT} state_t;
state_t state, nxt_state;

always_ff @(posedge clk, negedge rst_n) begin
  if (!rst_n)
    state <= STRT_CNV;
  else
    state <= nxt_state;
end

always_comb begin
// Default outputs
nxt_state = state;
EN = 1'b0;
strt_cnv = 1'b0;
  case (state)
    // Conversion state to start the analog to digital conversion
    default : begin
      strt_cnv = 1'b1;
      nxt_state = CNV_CMPLT;
    end
    // Waits for the conversion to be complete to increment bit counter
    CNV_CMPLT : begin
      if (cnv_cmplt) begin
	EN = 1'b1;
	nxt_state = STRT_CNV;
      end
    end

  endcase
end

///////////////////////////////////////////////////////////////////////////
// Flops to control slide potentiometers. Each one is enabled separately //
// based on the enable signal from the SM and their respective channel.	 //
///////////////////////////////////////////////////////////////////////////
always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n)
    POT_LP <= 12'h800;
  else if (EN && (chnnl == 3'b001)) begin
    POT_LP <= res;
  end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n)
    POT_B1 <= 12'h800;
  else if (EN && (chnnl == 3'b000)) begin
    POT_B1 <= res;
  end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n)
    POT_B2 <= 12'h800;
  else if (EN && (chnnl == 3'b100)) begin
    POT_B2 <= res;
  end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n)
    POT_B3 <= 12'h800;
  else if (EN && (chnnl == 3'b010)) begin
    POT_B3 <= res;
  end
end

always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n)
    POT_HP <= 12'h800;
  else if (EN && (chnnl == 3'b011)) begin
    POT_HP <= res;
  end
end

always_ff @(posedge clk, negedge rst_n) begin
 if (~rst_n)
    VOLUME <= 12'h800;
  else if (EN && (chnnl == 3'b111)) begin
    VOLUME <= res;
  end
end


endmodule

    
