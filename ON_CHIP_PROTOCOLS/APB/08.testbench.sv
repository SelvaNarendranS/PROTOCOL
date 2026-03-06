// APB - TESTBENCH
// `timescale 1ns/1ps

module testbench;
  
  // parameter
  parameter DATA_WIDTH  = 12;
  parameter DEPTH       = 4096;
  parameter ADDR_WIDTH  = 16;		// 12 address bits and 4 slave select bits
  
  reg 						pclk;
  reg 						presetn;			
  
  // input control signals
  reg [DATA_WIDTH-1:0]		apb_pwdata;			
  reg [ADDR_WIDTH-1:0]		apb_pwaddr;	
  reg [ADDR_WIDTH-1:0]		apb_praddr;
  reg 						apb_pwrite;			
  reg 						apb_tx_enable;		
  
  // output status signal
  wire [DATA_WIDTH-1:0]		apb_prdata;										
  wire    					busy;
  wire 		 				pslverr;
  
  // instantation
  apb_top_module #(.DATA_WIDTH(DATA_WIDTH),
                   .DEPTH(DEPTH),
                   .ADDR_WIDTH(ADDR_WIDTH))
  dut (.pclk			(pclk),
       .presetn			(presetn),
       .apb_pwdata		(apb_pwdata),
       .apb_pwaddr		(apb_pwaddr),
       .apb_praddr		(apb_praddr),
       .apb_prdata		(apb_prdata),
       .apb_pwrite		(apb_pwrite),
       .apb_tx_enable	(apb_tx_enable),
       .busy			(busy),
       .pslverr			(pslverr)
      );
  
  // clock generation
  initial begin
    pclk = 0;
    forever #5 pclk = ~pclk;
  end
  
  // display
  initial begin
    $monitor("time = %0t | presetn = %0d | psel = 1 | apb_pwdata = %0d | apb_pwaddr = %0d | apb_praddr = %0d |  apb_prdata = %0d | apb_pwrite = %0d | apb_tx_enable = %0d | busy = %0d | pslverr = %0d | masst = %0d | full = %0d | empty = %0d", $time, presetn, apb_pwdata, apb_pwaddr, apb_praddr, apb_prdata, apb_pwrite, apb_tx_enable, busy, pslverr, dut.master.state, dut.slave3.full, dut.slave3.empty);
  end
//   initial begin
//     $monitor("time = %0t | presetn = %0d | pready = %0d | apb_pwdata = %0d | apb_paddr = %0d | apb_prdata = %0d | apb_pwrite = %0d(%0d) | apb_tx_enable = %0d | busy = %0d | pslverr = %0d | master state = %d", $time, presetn, dut.master.pready, apb_pwdata, apb_paddr, dut.slv_prdata, apb_pwrite, dut.master.pwrite, apb_tx_enable, busy, pslverr, dut.master.state);
//   end
  
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars;
    
    // reset
    presetn 	  = 0;
    apb_pwdata	  = 0;
    apb_pwaddr	  = 0;
    apb_praddr	  = 0;
    apb_pwrite	  = 0;
    apb_tx_enable = 0;
    
    #100;
    
    // reset release
    presetn = 1;
    
    #10;      
        
    // write task calling
    execute($random, 32'h1F1F, 0, 1);		// slave 2
    execute($random, 32'h0314, 0, 1);		// slave 1
    execute(117, 32'h2643, 0, 1);			// slave 3
    execute($random, 32'h223, 0, 1);		// slave 3
    
    // read task calling
    execute(0, 0, 32'h1F1F, 0);			// slave 2
    execute(0, 0, 32'h0314, 0);			// slave 1
    execute(0, 0, 32'h0F1F, 0);			// slave 1
    execute(0, 0, 32'h2643, 0);			// slave 3
    execute($random, 32'h223, 0, 0);		// slave 3
    
    #1000;
    $finish;
  end
  
  task execute(
    input [DATA_WIDTH-1:0] 	  apb_pdata,
    input [31:0] 			  apb_pwaddress,
    input [31:0] 			  apb_praddress,
    input 			          apb_pwr
  );
    
    @(negedge pclk);
    apb_pwdata 	  = apb_pdata;
    apb_pwaddr 	  = apb_pwaddress;
    apb_praddr 	  = apb_praddress;
    apb_pwrite 	  = apb_pwr;
    
    $write("\n\t----------------------- %s ------------------------", (apb_pwrite) ? "WRITE CONDITION" : "READ CONDITION");
    $display("%s",  (apb_pwrite) ? 
             ((apb_pwaddr[15:12] == 0) ? "SLAVE1 - SELECTED" : 
              (apb_pwaddr[15:12] == 1) ? "SLAVE2 - SELECTED" :
              (apb_pwaddr[15:12] == 2) ? "SLAVE3 - SELECTED" : 
              (apb_pwaddr[15:12] == 3) ? "SLAVE4 - SELECTED" : "NA") 
             :
             ((apb_praddr[15:12] == 0) ? "SLAVE1 - SELECTED" : 
              (apb_praddr[15:12] == 1) ? "SLAVE2 - SELECTED" :
              (apb_praddr[15:12] == 2) ? "SLAVE3 - SELECTED" : 
              (apb_praddr[15:12] == 3) ? "SLAVE4 - SELECTED" : "NA") 
            );
    
    $display("\t Sending input's --> pwdata = %0d | pwaddr = %0h | praddr = %0h | pread/write = %0d", apb_pwdata, apb_pwaddr, apb_praddr,  apb_pwrite);
    
    apb_tx_enable = 1;
//     @(posedge busy);
    if (!busy) @(posedge busy);
    
    @(negedge dut.master.pready);
//     #10;
    apb_tx_enable = 0;
    
     @(negedge busy);    
    
  endtask
endmodule