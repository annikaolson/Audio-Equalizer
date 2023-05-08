module PDM(clk, rst_n, duty, PDM, PDM_n);
  input clk, rst_n;
  input [15:0] duty;
  output reg PDM;
  output reg PDM_n;

// Intermediate signals //
logic [15:0] dutyQ, interQ, AgteB;

///////////////////////////////////////
// A greater than or equal to B      //
// Either gets all ones or all zeros //
///////////////////////////////////////
assign AgteB = (dutyQ >= interQ) ? 16'hFFFF : 16'h0000;

// Duty ff //
always_ff @ (posedge clk, negedge rst_n) begin
  if (!rst_n)		dutyQ <= 16'h0000;
  else 			dutyQ <= duty; end

// Intermediate ff //
always_ff @ (posedge clk, negedge rst_n) begin
  if (!rst_n)   	interQ <= 16'h0000;
  else   			interQ <= AgteB - dutyQ + interQ; end // infers the ALUs 
  
/////////////////////////////////////////
// Flop for the PDM and NOT PDM signal //
/////////////////////////////////////////
always_ff @ (posedge clk, negedge rst_n) begin
  if (!rst_n) begin
    PDM <= 1'b0;
    PDM_n <= 1'b1; end
  else begin			
    PDM <= AgteB[0];
    PDM_n <= ~AgteB[0]; end
end

endmodule
