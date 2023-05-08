module band_scale(POT, audio, scaled, rst_n, clk);

input rst_n, clk;
input [11:0]POT;
input signed [15:0]audio;
output [15:0]scaled;

logic [23:0]potSq;
logic signed [12:0]signedPot; 
logic signed [28:0]FIRscaled; 
logic flagPos, flagNeg, upperZero, upperOnes;
logic [23:0] potSq_q1;

////////////////////////////////////
// Square the potentiometer value //
////////////////////////////////////
assign potSq = POT*POT;

///////////////////////////////////////////////////////////
// flop the squared potentiometer signal to meet timing. //
// it needs to be ready before next arithmetic block     // 
///////////////////////////////////////////////////////////
always_ff @(posedge clk, negedge rst_n) begin
  if (!rst_n)
    potSq_q1 <= '0;
  else
    potSq_q1 <= potSq;
end

//////////////////////////////////////////////////////////////////
// Concatenate with 0 as MSB to make it a positive signed value //
//////////////////////////////////////////////////////////////////
assign signedPot = {1'b0, potSq_q1[23:12]};

// Scaled potentiometer value
assign FIRscaled = signedPot * audio;

////////////////////////////////////////////////////////////////////////////////
// saturation process by detecting if any of the upper bits are zeros or ones //
////////////////////////////////////////////////////////////////////////////////
assign upperZero = !(FIRscaled[27] && FIRscaled[26] && FIRscaled[25]);
assign upperOnes = FIRscaled[27] || FIRscaled[26] || FIRscaled[25];

////////////////////////////////////////////////////////////////////////////////////////////////////////////
// if "and" is 0 and number is negative, set flag to saturate negative (saturate to most negative number) //
// if "or" is 1 and number is positive, set flag to saturate positive (saturate to most positive number)  //
////////////////////////////////////////////////////////////////////////////////////////////////////////////
assign flagNeg = (FIRscaled[28] && upperZero);
assign flagPos = (!FIRscaled[28] && upperOnes);

////////////////////////////////////////////////////////////////////////
// if flag is 0, then neg flag is set. if flag is 1, pos flag is set. //
// saturate if either are asserted. otherwise, use upper 16 bits of   //
// scaled value.						      //
////////////////////////////////////////////////////////////////////////
assign scaled = flagNeg ? 16'h8000 :
		flagPos ? 16'h7FFF : 
		FIRscaled[25:10];


endmodule
