module Equalizer_tb();

reg clk,RST_n, rst_n;
reg next_n,prev_n,Flt_n;
reg [11:0] LP,B1,B2,B3,HP,VOL;

wire [7:0] LED;
wire ADC_SS_n,ADC_MOSI,ADC_MISO,ADC_SCLK;
wire I2S_data,I2S_ws,I2S_sclk;
wire cmd_n,RX_TX,TX_RX;
wire lft_PDM,rght_PDM;
wire lft_PDM_n,rght_PDM_n;

// Test Variables 
realtime end_time;
realtime start_time;
realtime period;

// variables for all tests passed
logic fails;

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
                    .MOSI(ADC_MOSI),.LP(LP),.B1(B1),.B2(B2),.B3(B3),.HP(HP),.VOL(VOL));
     
// Creates Equalizer PDM for Self-Checking
InversePDM iRevPDM(.clk(clk), .rst_n(rst_n), .period_cnt(8'hAA));


// detecting when wave crosses 0	
logic waitForFall, waitForRise;	

//waitForFall
always_ff @(posedge clk)
		if (iDUT.speaker.lft_reg > 16'h8200)
			waitForFall <= 1'b1;
		else 
			waitForFall <= 1'b0;

// waitForRise
always_ff @(posedge clk)
		if (iDUT.speaker.lft_reg < 16'h7FD0)
			waitForRise <= 1'b1;
		else 
			waitForRise <= 1'b0;		

// Tests that the bands each work and produce a wave with a non-zero period
task automatic TestBand(ref reg [11:0] LP, input int LP1, ref reg [11:0] B1, input int B11, ref reg [11:0] B2, input int B21, 
                        ref reg [11:0] B3, input int B31, ref reg [11:0] HP, input int HP1, ref logic clk);
    begin 
	  LP = LP1;
	  B1 = B11;
	  B2 = B21;
	  B3 = B31;
	  HP = HP1;
      start_time = 0;
      end_time = 0;
      
	  // Tests LP Band
      if (LP == 12'h800) begin 
        repeat (25000) @(posedge clk) begin
		  if(!waitForFall) begin
            start_time = $realtime;
              if(!waitForRise) begin // crosses 0
                if(!waitForFall) begin // crosses 0
		          @(posedge clk);
		          end_time = $realtime;
		        end
	          end
          end
	    end
        period = (1 / (end_time - start_time));      
        if (period == 0) begin
          $display ("LP Band Test Failed!");   
	      fails++;
          $stop;    
        end  
      end 
      // Tests B1 Band
      else if (B1 == 12'h800) begin 
        repeat (25000) @(posedge clk) begin
		  if(!waitForFall) begin
            start_time = $realtime;
              if(!waitForRise) begin // crosses 0
                if(!waitForFall) begin // crosses 0
		          @(posedge clk);
		          end_time = $realtime;
		        end
	          end
          end
	    end
        period = (1 / (end_time - start_time));      
        if (period == 0) begin
          $display ("LP Band Test Failed!");   
	      fails++;
          $stop;    
        end  
      end 
      // Tests B2 Band
      if (B2 == 12'h800) begin 
      repeat (25000) @(posedge clk) begin
		if(!waitForFall) begin
          start_time = $realtime;
            if(!waitForRise) begin // crosses 0
              if(!waitForFall) begin // crosses 0
		        @(posedge clk);
		        end_time = $realtime;
		      end
	        end
        end
	  end
      period = (1 / (end_time - start_time));      
      if (period == 0) begin
        $display ("LP Band Test Failed!");   
	    fails++;
        $stop;    
      end  
    end  
    // Tests B3 Band
    if (B3 == 12'h800) begin 
        repeat (25000) @(posedge clk) begin
		  if(!waitForFall) begin
            start_time = $realtime;
              if(!waitForRise) begin // crosses 0
                if(!waitForFall) begin // crosses 0
		          @(posedge clk);
		          end_time = $realtime;
		        end
	          end
          end
	    end
        period = (1 / (end_time - start_time));      
        if (period == 0) begin
          $display ("LP Band Test Failed!");   
	      fails++;
          $stop;    
        end  
      end 
    // Tests HP Band
    else if (LP == 12'h800) begin 
        repeat (25000) @(posedge clk) begin
		  if(!waitForFall) begin
            start_time = $realtime;
              if(!waitForRise) begin // crosses 0
                if(!waitForFall) begin // crosses 0
		          @(posedge clk);
		          end_time = $realtime;
		        end
	          end
          end
	    end
        period = (1 / (end_time - start_time));      
        if (period == 0) begin
          $display ("LP Band Test Failed!");   
	      fails++;
          $stop;    
        end  
      end 
	  
      LP = 12'h000;
	  B1 = 12'h000;
	  B2 = 12'h000;
	  B3 = 12'h000;
	  HP = 12'h000;
	  VOL = 12'h000;	  
    end 
   endtask	

  // test for amplitude of sine wave to ensure increasing the pot increaes the frequency
  logic [15:0]currentPeak, peak, waveMax1, waveMax2, maxPeak;

  task automatic TestAmplitude(ref reg [11:0] LP, input int LP1, ref reg [11:0] B1, input int B11, ref reg [11:0] B2, input int B21, 
                     ref reg [11:0] B3, input int B31, ref reg [11:0] HP, input int HP1, ref logic clk);
    
	begin
		LP = LP1;
	    B1 = B11;
	    B2 = B21;
	    B3 = B31;
	    HP = HP1;
        // Tests LP Band
        if (LP != 12'h000) begin
			repeat (25000) @(posedge clk) begin
				currentPeak = iDUT.speaker.lft_reg;
				@(posedge clk);
				peak = iDUT.speaker.lft_reg;
				if (currentPeak > peak)
					maxPeak = currentPeak;
			end
		end
        // Tests B1 Band
        else if (B1 != 12'h000) begin
          repeat (25000) @(posedge clk) begin
				currentPeak = iDUT.speaker.lft_reg;
				@(posedge clk);
				peak = iDUT.speaker.lft_reg;
				if (currentPeak > peak)
					peak = currentPeak;
			end 
		end
        // Tests B2 Band
        else if (B2 != 12'h000) begin
          repeat (25000) @(posedge clk) begin
				currentPeak = iDUT.speaker.lft_reg;
				@(posedge clk);
				peak = iDUT.speaker.lft_reg;
				if (currentPeak > peak)
					peak = currentPeak;
			end
		end
        // Tests B3 Band
        else if (B3 != 12'h000) begin
          repeat (25000) @(posedge clk) begin
				currentPeak = iDUT.speaker.lft_reg;
				@(posedge clk);
				peak = iDUT.speaker.lft_reg;
				if (currentPeak > peak)
					peak = currentPeak;
			end
		end
        // Tests HP Band
        else if (HP != 12'h000) begin
          repeat (25000) @(posedge clk) begin
				currentPeak = iDUT.speaker.lft_reg;
				@(posedge clk);
				peak = iDUT.speaker.lft_reg;
				if (currentPeak > peak)
					peak = currentPeak;
			end
		end
	  LP = 12'h000;
	  B1 = 12'h000;
	  B2 = 12'h000;
	  B3 = 12'h000;
	  HP = 12'h000;
	  VOL = 12'h000;
    end
  endtask 

  task QueueFull ();
    fork 
	  begin : timeout
	    repeat (2500000) @(posedge clk);
		  $display ("Timed out waiting for queue to fill");
		  $stop();
	  end : timeout
	  begin
	    @(posedge iDUT.engine.lfq.full);
		disable timeout;
	  end
	join 
  endtask

  // begin calling tasks
  initial begin
    clk = 1'b0;
    RST_n  = 1'b0;
	fails = 1'b0;
	currentPeak = 16'h0000;
	maxPeak = 16'h0000;
	waveMax1 = 16'h0000;
	waveMax2 = 16'h0000;
	peak = 16'h0000;
	next_n = 1'b0;
	prev_n = 1'b0;
	Flt_n = 1'b1;
    LP = 12'h000;
	B1 = 12'h000;
	B2 = 12'h000;
	B3 = 12'h000;
	HP = 12'h000;
	VOL = 12'h111;
	rst_n = 1'b0;
	
    @(posedge clk);
	RST_n = 1'b1;
    @(negedge clk);
	rst_n = 1'b1;
	
	// Wait for low fequency queue to be full
	QueueFull();

	// Testing Amplitude
	// Tests LP_FIR Band
	TestAmplitude(.LP(LP), .LP1(12'h800), .B1(B1), .B11(B1), .B2(B2), .B21(B2), .B3(B3), .B31(B3), .HP(HP), .HP1(HP), .clk(clk));
	waveMax1 = maxPeak;
	TestAmplitude(.LP(LP), .LP1(12'h900), .B1(B1), .B11(B1), .B2(B2), .B21(B2), .B3(B3), .B31(B3), .HP(HP), .HP1(HP), .clk(clk));
	waveMax2 = maxPeak;
	if (waveMax1 > waveMax2) begin
		$display ("LP Band Test Failed!");   
		fails++;
        $stop;
	end
	// Tests B1_FIR Band
	TestAmplitude(.LP(LP), .LP1(LP), .B1(B1), .B11(12'h800), .B2(B2), .B21(B2), .B3(B3), .B31(B3), .HP(HP), .HP1(HP), .clk(clk));
	waveMax1 = maxPeak;
	TestAmplitude(.LP(LP), .LP1(LP), .B1(B1), .B11(12'h900), .B2(B2), .B21(B2), .B3(B3), .B31(B3), .HP(HP), .HP1(HP), .clk(clk));
	waveMax2 = maxPeak;
	if (waveMax1 > waveMax2) begin
		$display ("B1 Band Test Failed!");   
		fails++;
        $stop;
	end
	// Tests B2_FIR Band
	TestAmplitude(.LP(LP), .LP1(LP), .B1(B1), .B11(B1), .B2(B2), .B21(12'h800), .B3(B3), .B31(B3), .HP(HP), .HP1(HP), .clk(clk));
	waveMax1 = maxPeak;
	TestAmplitude(.LP(LP), .LP1(LP), .B1(B1), .B11(B1), .B2(B2), .B21(12'h900), .B3(B3), .B31(B3), .HP(HP), .HP1(HP), .clk(clk));
	waveMax2 = maxPeak;
	if (waveMax1 > waveMax2) begin
		$display ("B2 Band Test Failed!"); 
		fails++;
        $stop;
	end
	// Tests B3_FIR Band
	TestAmplitude(.LP(LP), .LP1(LP), .B1(B1), .B11(B1), .B2(B2), .B21(B2), .B3(B3), .B31(12'h800), .HP(HP), .HP1(HP), .clk(clk));
	waveMax1 = maxPeak;
	TestAmplitude(.LP(LP), .LP1(LP), .B1(B1), .B11(B1), .B2(B2), .B21(B2), .B3(B3), .B31(12'h900), .HP(HP), .HP1(HP), .clk(clk));
	waveMax2 = maxPeak;
	if (waveMax1 > waveMax2) begin
		$display ("B3 Band Test Failed!");   
		fails++;
        $stop;
	end
	// Tests HP_FIR Band
	TestAmplitude(.LP(LP), .LP1(LP), .B1(B1), .B11(B1), .B2(B2), .B21(B2), .B3(B3), .B31(B3), .HP(HP), .HP1(12'h800), .clk(clk));
	waveMax1 = maxPeak;
	TestAmplitude(.LP(LP), .LP1(LP), .B1(B1), .B11(B1), .B2(B2), .B21(B2), .B3(B3), .B31(B3), .HP(HP), .HP1(12'h900), .clk(clk));
	waveMax2 = maxPeak;
	if (waveMax1 > waveMax2) begin
		$display ("HP Band Test Failed!");   
		fails++;
        $stop;
	end
	
		
	// Tests LP_FIR Band
	TestBand(.LP(LP), .LP1(12'h800), .B1(B1), .B11(B1), .B2(B2), .B21(B2), .B3(B3), .B31(B3), .HP(HP), .HP1(HP), .clk(clk));
	// Tests B1_FIR Band
	TestBand(.LP(LP), .LP1(LP), .B1(B1), .B11(12'h800), .B2(B2), .B21(B2), .B3(B3), .B31(B3), .HP(HP), .HP1(HP), .clk(clk));
	// Tests B2_FIR Band
	TestBand(.LP(LP), .LP1(LP), .B1(B1), .B11(B1), .B2(B2), .B21(12'h800), .B3(B3), .B31(B3), .HP(HP), .HP1(HP), .clk(clk));
	// Tests B3_FIR Band
	TestBand(.LP(LP), .LP1(LP), .B1(B1), .B11(B1), .B2(B2), .B21(B2), .B3(B3), .B31(12'h800), .HP(HP), .HP1(HP), .clk(clk));
	// Tests HP_FIR Band
	TestBand(.LP(LP), .LP1(LP), .B1(B1), .B11(B1), .B2(B2), .B21(B2), .B3(B3), .B31(B3), .HP(HP), .HP1(12'h800), .clk(clk));
	
	// display pass message
	if (fails == 0)
		$display ("All tests passed!");
		
	$stop;  
  end
  	
  always
    #5 clk = ~ clk;
  
endmodule	

// tests inverse PDM produces a wave
module InversePDM(clk, rst_n, period_cnt);
  input clk, rst_n;
  input [7:0] period_cnt;
 
  logic [13:0] duty_cnt;
  logic [13:0] hold_reg;
  logic [7:0] cur_per_cnt;
  
  always @(posedge clk, period_cnt) begin
   if (~rst_n) begin
     duty_cnt =14'd0;
     hold_reg = 14'd0;
     cur_per_cnt = 8'd0;  
   end
   else if (cur_per_cnt == period_cnt) begin
	 hold_reg = duty_cnt;
     duty_cnt = 14'd0;
	 cur_per_cnt = 8'd0;
   end
   else begin
	if (iDUT.speaker.lft_PDM == 1'b1)
	  ++duty_cnt;
    ++cur_per_cnt;
   end
 end 
endmodule  