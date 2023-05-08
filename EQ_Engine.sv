module EQ_Engine(clk, rst_n, aud_in_lft, aud_in_rght, vld, aud_out_lft, aud_out_rght, POT_LP, POT_B1, POT_B2, POT_B3, POT_HP, VOL_POT);

input clk, rst_n;
input [11:0] POT_LP, POT_B1, POT_B2, POT_B3, POT_HP, VOL_POT;
input [15:0] aud_in_lft, aud_in_rght;
input vld;
output [15:0] aud_out_lft, aud_out_rght;

logic vld_lf, alt;
logic [15:0] lft_out_lf, rght_out_lf, lft_out_hf, rght_out_hf;
logic sequencing_lf, sequencing_hf;
logic signed [15:0] lft_lp_out, rght_lp_out, lft_b1_out, rght_b1_out, lft_b2_out, rght_b2_out, lft_b3_out, rght_b3_out, lft_hp_out, rght_hp_out;
logic signed [15:0] scaled_lp_lft, scaled_b1_lft, scaled_b2_lft, scaled_b3_lft, scaled_hp_lft, scaled_lp_rght, scaled_b1_rght, scaled_b2_rght, scaled_b3_rght, scaled_hp_rght;
logic signed [15:0] scaled_lp_lft_ff, scaled_b1_lft_ff, scaled_b2_lft_ff, scaled_b3_lft_ff, scaled_hp_lft_ff, scaled_lp_rght_ff, scaled_b1_rght_ff, scaled_b2_rght_ff, scaled_b3_rght_ff, scaled_hp_rght_ff;
logic signed [15:0] band_scale_sum_lft_ff, band_scale_sum_rght_ff, band_scale_sum_rght, band_scale_sum_lft;
logic signed [28:0] aud_out_mult_lft, aud_out_mult_rght;

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Instantiate the low frequency circular queue. This takes the left and right audio sample, and provides the input to the FIR filters. //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
low_freq_queue lfq(.clk(clk), .rst_n(rst_n), .lft_smpl(aud_in_lft), .rght_smpl(aud_in_rght), .wrt_smpl(vld_lf), .lft_out(lft_out_lf), .rght_out(rght_out_lf), .sequencing(sequencing_lf));

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Instantiate the low frequenecy (LP and B1) FIR filters. The output of these are used as audio inputs to the bandscale to be scaled. //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
FIR_LP lowpassfir(.lft_out(lft_lp_out), .rght_out(rght_lp_out), .clk(clk), .rst_n(rst_n), .lft_in(lft_out_lf), .rght_in(rght_out_lf), .sequencing(sequencing_lf));
FIR_B1 b1fir(.lft_out(lft_b1_out), .rght_out(rght_b1_out), .clk(clk), .rst_n(rst_n), .lft_in(lft_out_lf), .rght_in(rght_out_lf), .sequencing(sequencing_lf));

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Instantiate the high frequency circular queue. This takes the left and right audio sample, and provides the input to the FIR filters. //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
high_freq_queue hfq(.clk(clk), .rst_n(rst_n), .lft_smpl(aud_in_lft), .rght_smpl(aud_in_rght), .wrt_smpl(vld), .lft_out(lft_out_hf), .rght_out(rght_out_hf), .sequencing(sequencing_hf));

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Instantiate the high frequenecy (B2, B3, HP) FIR filters. The output of these are used as audio inputs to the bandscale to be scaled. //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
FIR_B2 b2fir(.lft_out(lft_b2_out), .rght_out(rght_b2_out), .clk(clk), .rst_n(rst_n), .lft_in(lft_out_hf), .rght_in(rght_out_hf), .sequencing(sequencing_hf));
FIR_B3 b3fir(.lft_out(lft_b3_out), .rght_out(rght_b3_out), .clk(clk), .rst_n(rst_n), .lft_in(lft_out_hf), .rght_in(rght_out_hf), .sequencing(sequencing_hf));
FIR_HP highpassfir(.lft_out(lft_hp_out), .rght_out(rght_hp_out), .clk(clk), .rst_n(rst_n), .lft_in(lft_out_hf), .rght_in(rght_out_hf), .sequencing(sequencing_hf));

/////////////////////////////////////////////////////////////////////////////
// Logic to detect a write signal on every other valid for low frequencies //
/////////////////////////////////////////////////////////////////////////////
always_ff @(posedge clk, negedge rst_n) begin
  if (~rst_n)
    alt = 1'b0;
  else if (vld)
    alt = ~alt;
end

assign vld_lf = (alt & vld);

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Hook up fir filters to the left audio section of bandscale, each with a different POT connection based on the FIR input. //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
band_scale bsleftlp(.POT(POT_LP), .audio(lft_lp_out), .scaled(scaled_lp_lft_ff), .clk(clk), .rst_n(rst_n));
band_scale bsleftb1(.POT(POT_B1), .audio(lft_b1_out), .scaled(scaled_b1_lft_ff), .clk(clk), .rst_n(rst_n));
band_scale bsleftb2(.POT(POT_B2), .audio(lft_b2_out), .scaled(scaled_b2_lft_ff), .clk(clk), .rst_n(rst_n));
band_scale bsleftb3(.POT(POT_B3), .audio(lft_b3_out), .scaled(scaled_b3_lft_ff), .clk(clk), .rst_n(rst_n));
band_scale bslefthp(.POT(POT_HP), .audio(lft_hp_out), .scaled(scaled_hp_lft_ff), .clk(clk), .rst_n(rst_n));

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Sum all scaled left outputs; the sum terms are from the flop to meet timing, and they go a variable that is also flopped. //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
assign band_scale_sum_lft_ff = (scaled_lp_lft + scaled_b1_lft + scaled_b2_lft + scaled_b3_lft + scaled_hp_lft);

////////////////////////////////////////////////////////////////////////////////
// Multiplication of the band scale sum and the signed volume POT value.      //
// Then assign the left engine output to be the upper 16 bits of that result. //
////////////////////////////////////////////////////////////////////////////////
assign aud_out_mult_lft = (band_scale_sum_lft * {1'b0, VOL_POT});
assign aud_out_lft = aud_out_mult_lft [27:12];

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Hook up fir filters to the right audio section of bandscale, each with a different POT connection based on the FIR input. //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
band_scale bsrightlp(.POT(POT_LP), .audio(rght_lp_out), .scaled(scaled_lp_rght_ff), .clk(clk), .rst_n(rst_n));
band_scale bsrightb1(.POT(POT_B1), .audio(rght_b1_out), .scaled(scaled_b1_rght_ff), .clk(clk), .rst_n(rst_n));
band_scale bsrightb2(.POT(POT_B2), .audio(rght_b2_out), .scaled(scaled_b2_rght_ff), .clk(clk), .rst_n(rst_n));
band_scale bsrightb3(.POT(POT_B3), .audio(rght_b3_out), .scaled(scaled_b3_rght_ff), .clk(clk), .rst_n(rst_n));
band_scale bsrighthp(.POT(POT_HP), .audio(rght_hp_out), .scaled(scaled_hp_rght_ff), .clk(clk), .rst_n(rst_n));

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Sum all scaled left outputs; the sum terms are from the flop to meet timing, and they go a variable that is also flopped. //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
assign band_scale_sum_rght_ff = (scaled_lp_rght + scaled_b1_rght + scaled_b2_rght + scaled_b3_rght + scaled_hp_rght);

////////////////////////////////////////////////////////////////////////////////
// Multiplication of the band scale sum and the signed volume POT value.      //
// Then assign the left engine output to be the upper 16 bits of that result. //
////////////////////////////////////////////////////////////////////////////////
assign aud_out_mult_rght = (band_scale_sum_rght * {1'b0, VOL_POT});
assign aud_out_rght = aud_out_mult_rght [27:12];

/////////////////////////////////////////
// Flop to pipeline band scale outputs //
/////////////////////////////////////////
always_ff @(posedge clk, negedge rst_n) begin
  if (!rst_n) begin
    scaled_lp_lft <= '0;
    scaled_b1_lft <= '0;
    scaled_b2_lft <= '0;
    scaled_b3_lft <= '0;
    scaled_hp_lft <= '0;
    scaled_lp_rght <= '0;
    scaled_b1_rght <= '0;
    scaled_b2_rght <= '0;
    scaled_b3_rght <= '0;
    scaled_hp_rght <= '0;
  end
  else begin
    scaled_lp_lft <= scaled_lp_lft_ff;
    scaled_b1_lft <= scaled_b1_lft_ff;
    scaled_b2_lft <= scaled_b2_lft_ff;
    scaled_b3_lft <= scaled_b3_lft_ff;
    scaled_hp_lft <= scaled_hp_lft_ff;
    scaled_lp_rght <= scaled_lp_rght_ff;
    scaled_b1_rght <= scaled_b1_rght_ff;
    scaled_b2_rght <= scaled_b2_rght_ff;
    scaled_b3_rght <= scaled_b3_rght_ff;
    scaled_hp_rght <= scaled_hp_rght_ff;
  end
end

////////////////////////////////////////////////
// Flop to pipeline left and right summations //
////////////////////////////////////////////////
always_ff @(posedge clk, negedge rst_n) begin
  if (!rst_n) begin
    band_scale_sum_lft <= '0;
    band_scale_sum_rght <= '0;
  end
  else begin
    band_scale_sum_lft <= band_scale_sum_lft_ff;
    band_scale_sum_rght <= band_scale_sum_rght_ff;
  end
end


endmodule
