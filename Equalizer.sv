module Equalizer(clk, RST_n, prev_n, next_n, ADC_MISO, ADC_MOSI, LED, ADC_SCLK, ADC_SS_n, lft_PDM, rght_PDM, lft_PDM_n, rght_PDM_n, I2S_sclk, I2S_ws, I2S_data, cmd_n, RX, TX, sht_dwn, Flt_n);

input RST_n, clk;
input prev_n, next_n;
input I2S_sclk, I2S_ws, I2S_data;
input ADC_MISO;
output ADC_SS_n, ADC_SCLK, ADC_MOSI;
output lft_PDM, rght_PDM, lft_PDM_n, rght_PDM_n;
output [7:0] LED;
output cmd_n, TX;
input RX;
output logic sht_dwn;
input Flt_n;

logic rst_n;
logic [11:0] POT_LP, POT_B1, POT_B2, POT_B3, POT_HP, VOL;
logic vld;
logic [15:0] aud_out_lft, aud_out_rght;
logic [15:0] aud_in_lft, aud_in_rght;
logic [23:0] I2S_lft_out, I2S_rght_out;

reg [17:0] amp_en_cntr;
logic flt_q1, flt_q2;

assign aud_in_lft = I2S_lft_out [23:8];
assign aud_in_rght = I2S_rght_out [23:8];

/////////////////////////////////////////////////////////////////////////////////////////////////////////
// Instantiate the slide interface. This controls the potentiometer values via the sliders on the FPGA //
/////////////////////////////////////////////////////////////////////////////////////////////////////////
slide_intf slider(.POT_LP(POT_LP), .POT_B1(POT_B1), .POT_B2(POT_B2), .POT_B3(POT_B3), .POT_HP(POT_HP), .VOLUME(VOL), .clk(clk), .rst_n(rst_n), .SS_n(ADC_SS_n), .SCLK(ADC_SCLK), .MOSI(ADC_MOSI), .MISO(ADC_MISO));

//////////////////////////////////////////////////////////////////////////////////////////
// Instantiate the engine. This controls the equalizer, as it filters the audio signals //
//////////////////////////////////////////////////////////////////////////////////////////
EQ_Engine engine(.clk(clk), .rst_n(rst_n), .aud_in_lft(aud_in_lft), .aud_in_rght(aud_in_rght), .vld(vld), .aud_out_lft(aud_out_lft), .aud_out_rght(aud_out_rght), .POT_LP(POT_LP), .POT_B1(POT_B1), .POT_B2(POT_B2), .POT_B3(POT_B3), .POT_HP(POT_HP), .VOL_POT(VOL));

///////////////////////////////////////////////////
// Instantiate the driver for the speaker output //
///////////////////////////////////////////////////
spkr_drv speaker(.clk(clk), .rst_n(rst_n), .vld(vld), .lft_chnnl(aud_out_lft), .rght_chnnl(aud_out_rght), .lft_PDM(lft_PDM), .rght_PDM(rght_PDM), .lft_PDM_n(lft_PDM_n), .rght_PDM_n(rght_PDM_n));

////////////////////////////////////////////////////////////////////////////////////////
// Instantiate the Bluetooth interface, the bluetooth connection to the speaker setup //
////////////////////////////////////////////////////////////////////////////////////////
BT_intf bluetooth(.next_n(next_n), .prev_n(prev_n), .cmd_n(cmd_n), .TX(TX), .RX(RX), .clk(clk), .rst_n(rst_n));

/////////////////////////////////////////////////////////////////////////////////////
// Instantiate reset_synch. Reset synchronizer to create our internal reset signal //
/////////////////////////////////////////////////////////////////////////////////////
rst_synch reset(.RST_n(RST_n), .clk(clk), .rst_n(rst_n));

//////////////////////////////////////////////////////////////////////////////////////////
// Instantiate I2S Serf, provides the left and right channel audio data for the engine. //
// Connects the RN52 Bluetooth module to the engine of the equalizer.			//
//////////////////////////////////////////////////////////////////////////////////////////
I2S_Serf i2s(.clk(clk), .rst_n(rst_n), .I2S_sclk(I2S_sclk), .I2S_ws(I2S_ws), .I2S_data(I2S_data), .lft_chnnl(I2S_lft_out), .rght_chnnl(I2S_rght_out), .vld(vld));

// Tie LED to low... don't need now
assign LED = '0;

//////////////////////////
// Infer sht_dwn logic //
////////////////////////
	
// Synch //
always_ff @(posedge clk, negedge rst_n) begin
  if (!rst_n) begin		
    flt_q1 <= 1'b1;
    flt_q2 <= 1'b1;
  end	// double flopped to synch
  else begin 
    flt_q1 <= Flt_n;
    flt_q2 <= flt_q1;
  end	// double flopped to synch
end

	
// Calculate sht_down // 
always @(posedge clk, negedge rst_n) begin  if (!rst_n)
    amp_en_cntr <= 18'h00000;  else if (!flt_q2)
    amp_en_cntr <= 18'h00000;  else if (amp_en_cntr <= 250000)
    amp_en_cntr <= amp_en_cntr + 1;
end
	
assign sht_dwn = (amp_en_cntr <= 250000);

endmodule
