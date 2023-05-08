module EQ_tb();
// inputs //
logic clk,RST_n, rst_n;
logic next_n,prev_n,Flt_n;
logic [11:0] LP,B1,B2,B3,HP,VOL;

// outputs //
logic [7:0] LED;
logic ADC_SS_n,ADC_MOSI,ADC_MISO,ADC_SCLK;
logic I2S_data,I2S_ws,I2S_sclk;
logic cmd_n,RX_TX,TX_RX;
logic lft_PDM,rght_PDM;
logic lft_PDM_n,rght_PDM_n;

rst_synch reset(.RST_n(RST_n), .clk(clk), .rst_n(rst_n));

//////////////////////
// Instantiate DUT //
////////////////////
Equalizer iDUT(.clk(clk),.RST_n(RST_n),.LED(LED),.ADC_SS_n(ADC_SS_n),
                .ADC_MOSI(ADC_MOSI),.ADC_SCLK(ADC_SCLK),.ADC_MISO(ADC_MISO),
                .I2S_data(I2S_data),.I2S_ws(I2S_ws),.I2S_sclk(I2S_sclk),.cmd_n(cmd_n),
				.sht_dwn(sht_dwn),.lft_PDM(lft_PDM),.rght_PDM(rght_PDM),
				.lft_PDM_n(lft_PDM_n),.rght_PDM_n(rght_PDM_n),.Flt_n(Flt_n),
				.next_n(next_n),.prev_n(prev_n),.RX(RX_TX),.TX(TX_RX));
	
	
//////////////////////////////////////////
// Instantiate model of RN52 BT Module //
////////////////////////////////////////	
RN52 iRN52(.clk(clk),.RST_n(RST_n),.cmd_n(cmd_n),.RX(TX_RX),.TX(RX_TX),.I2S_sclk(I2S_sclk),
           .I2S_data(I2S_data),.I2S_ws(I2S_ws));

//////////////////////////////////////////////
// Instantiate model of A2D and Slide Pots //
////////////////////////////////////////////		   
A2D_with_Pots iPOTs(.clk(clk),.rst_n(rst_n),.SS_n(ADC_SS_n),.SCLK(ADC_SCLK),.MISO(ADC_MISO),
                    .MOSI(ADC_MOSI),.LP(LP),.B1(B1),.B2(B2),.B3(B3),.HP(HP),.VOL(VOL));// left and right sampled FFs //

// Clock //
always 
  #5 clk = ~clk;

// Testbench // 
initial begin
// Initialize
clk = 1'b0;
RST_n = 1'b1;
Flt_n = 1'b1;
@(posedge clk) RST_n =1'b0;
@(posedge clk);
@(negedge clk) RST_n = 1'b1; //deassert reset
next_n = 1'b1;
prev_n = 1'b1;
LP = 12'h800;
B1 = 12'h000;
B2 = 12'h000;
B3 = 12'h000;
HP = 12'h000;
VOL = 12'h112;
repeat (2500000) @(posedge clk); // runs for 2,500,000 clks
LP = 12'h000;
repeat (25000) @(posedge clk); // runs for 2,500,000 clk
	next_n = 1'b0; // assert next_n signal
@(posedge clk);
	next_n = 1'b1; // deassert next_n signal
 repeat (25000) @(posedge clk);
	next_n = 1'b0;
@(posedge clk);
	next_n = 1'b1;
 repeat (25000) @(posedge clk);
	next_n = 1'b0;
@(posedge clk);
	next_n = 1'b1;
 repeat (25000) @(posedge clk);
	prev_n = 1'b0; // assert prev_n signal
@(posedge clk);
	prev_n = 1'b1; // deassert prev_n signal
 repeat (25000) @(posedge clk);
	prev_n = 1'b0;
@(posedge clk);
	prev_n = 1'b1;
 repeat (25000) @(posedge clk);
$stop();
end


endmodule
