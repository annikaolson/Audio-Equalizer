module PB_release(PB, rst_n, released, clk);

input PB, rst_n, clk;
output released;

reg q1, q2, q3;

/////////////////////////////////////
// Synchronizes push button signal //
/////////////////////////////////////
always_ff @(posedge clk, negedge rst_n) begin
  if (!rst_n) begin
    q1 <= 1'b1;
    q2 <= 1'b1;
    q3 <= 1'b1;
  end
else begin
    q1 <= PB;
    q2 <= q1;
    q3 <= q2;
  end
end

// Edge detect for when button is released
assign released = !q3 && q2;

endmodule
