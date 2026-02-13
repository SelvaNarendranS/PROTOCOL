// testbench
`timescale 1ns/1ps
module testbench; 
  
  // parameter
  parameter TX_SYS_CLK   = 100_000_000; 		// Hz -- in hertz(mhz)
  parameter RX_SYS_CLK   = 50_000_000; 		
  parameter BAUD_RATE = 9600;				// baud rate
  parameter DATA_WIDTH = 8;
  
  // system
  reg 					tx_clk;
  reg					rx_clk;
  reg 					rst;
    
  // input signals
  reg 					tx_en;			// transaction enable / write enable
  reg 					baud_gen_en;
  reg 					parity_en;		// parity bit enable
  reg 					odd_r_even_parity;	// 0 - odd parity, 1 - even parity
  reg 					rx;				// rx port
  reg [DATA_WIDTH-1:0] 	data_in;		// parallel input data 
    
  // output signal
  wire 					tx;
  wire 					busy;
  wire 					done;
  wire 					framing_error;
  wire 					parity_error;
  wire [DATA_WIDTH-1:0]	data_out;			// parallel rx - out data
  
  
  // instantation
  uart_top_module #(.TX_SYS_CLK(TX_SYS_CLK),
                    .RX_SYS_CLK(RX_SYS_CLK),
                    .BAUD_RATE(BAUD_RATE),
                    .DATA_WIDTH(DATA_WIDTH))
  dut(
    .tx_clk(tx_clk),
    .rx_clk(rx_clk),
    .rst(rst),
    .tx_en(tx_en), 
    .baud_gen_en(baud_gen_en),
    .parity_en(parity_en),
    .odd_r_even_parity(odd_r_even_parity),
    .rx(rx),
    .data_in(data_in),
    .tx(tx),
    .busy(busy),
    .done(done),
    .framing_error(framing_error),
    .parity_error(parity_error),
    .data_out(data_out)
  );
  
  // system clock generation
  initial begin
    tx_clk = 0;
    forever #5 tx_clk = ~tx_clk;
  end
  
  // system clock generation
  initial begin
    rx_clk = 0;
    forever #10 rx_clk = ~rx_clk;
  end
  
  // loop back tx - rx connection
  assign #1 rx = tx;
  
  initial begin
    $monitor("Time = %0t | rst = %0d | data_in = %0d(%b) | tx = %0d | busy = %0d |rx = %0d | data_out = %0d(%b) | done = %0d | frm_err = %0d | pty_err = %0d | txst = %0d | rxst = %0d", $time, rst, data_in, data_in, tx, busy, rx, data_out, data_out, done, framing_error, parity_error, dut.transmit.state, dut.receive.state);
  end
  
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars;
    
    // Reset Sequence
    rst               = 0;
    tx_en             = 0;
    baud_gen_en       = 1;
    parity_en         = 0;
    odd_r_even_parity = 0;
    data_in           = 0;
    
    #100 rst = 1;
  
    // Run Testcases
    testcase(8'd40, 1, 1); 		// Even Parity
    testcase(8'd85, 1, 0); 		// Odd Parity
    testcase(8'd123, 0, 0);		// No Parity

    #1000 $finish;
  end
  
  task testcase(input [DATA_WIDTH-1:0] data, input p_en, input p_type);
    begin
      @(posedge tx_clk);
      data_in 			= data;
      parity_en 		= p_en;
      odd_r_even_parity = p_type;
      
      $display("\n------------------------- Sending Data: %d | parity en & type  = %0d & %0s-----------------------", data, p_en, (p_type) ? "EVEN" : "ODD");
      
      tx_en = 1;					// transmission start
      @(posedge busy); 				// wait till busy 1 - to allow transmitter to move to idle ---> start state
      
      tx_en = 0; 					// stansmission disable 
      @(posedge done);	

      #100; // Small delay
      if (data_out == data && !parity_error && !framing_error) begin
        $display("\t------------------------------------------------------------");
        $display("\t\t\t SUCCESS: Received %d correctly", data_out);
        $display("\t--------------------------------------------------------------");
      end
      else begin
        $display("\t------------------------------------------------------------");
        $display("\t\t\t ERROR: Data mismatch or error flagged");
        $display("\t--------------------------------------------------------------");
      end
      #200;
    end
  endtask
    
endmodule
