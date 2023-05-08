module rst_synch(RST_n, clk, rst_n);

input RST_n, clk;
output reg rst_n;
reg q1;

//////////////////////////////////////////////////////////
// creates an active low reset synchronizer to set our  //
// intermediate rst_n value via push button.	        //
//////////////////////////////////////////////////////////
always_ff @(negedge clk, negedge RST_n) begin
  if (!RST_n) begin
    q1 <= 1'b0;
    rst_n <= 1'b0;
  end
  else begin
   q1 <= 1'b1;
   rst_n <= q1;
  end
end

endmodule
