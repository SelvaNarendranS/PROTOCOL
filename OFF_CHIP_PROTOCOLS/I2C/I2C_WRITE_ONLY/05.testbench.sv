// i2c write only testbench
`timescale 1ns/1ps

module testbench;
  
  // parameters
  parameter SYS_CLK 	  = 50_000_000;		// hz - in hertz(mhz)
  parameter I2C_CLK 	  = 100_000;		// hz - in hertz(mhz)
  parameter ADDRESS_WIDTH = 7;
  parameter DATA_WIDTH    = 8;
  parameter SLAVE_ADDR 	  = 33;				// fixed lave address
  
  // input signals
  reg 					  clk;
  reg 					  rst;
  reg 					  i2c_clk_en; 	// i2c clock generator enable
  reg 					  i2c_en;	 	// i2c protocal enable
  reg [ADDRESS_WIDTH-1:0] addr;	
  reg 					  rw;		 	// read - 1, write - 0 ---> read & write command
  reg [DATA_WIDTH-1:0] 	  data_in;	// input data for transmission
  
  // output pins
  wire 					  busy;
  wire				  	  ack_err;		// acknowledgement error - not ack
  wire 					  done;
  wire [DATA_WIDTH-1:0]   data_out;		// output data -- received data
  wire 					  scl;			// serial clock
  wire					  sda;
  
  // instantation
  i2c_top_module #(.SYS_CLK(SYS_CLK),
                   .I2C_CLK(I2C_CLK),
                   .ADDRESS_WIDTH(ADDRESS_WIDTH),
                   .DATA_WIDTH(DATA_WIDTH),
                   .SLAVE_ADDR(SLAVE_ADDR))
  dut(
    .clk(clk),
    .rst(rst),
    .i2c_clk_en(i2c_clk_en),
    .i2c_en(i2c_en),
    .addr(addr),
    .rw(rw),
    .data_in(data_in),
    .busy(busy),		// master busy
    .ack_err(ack_err),	// master ack
    .done(done),		// slave done
    .data_out(data_out),
    .scl(scl),
    .sda(sda)
  );
  
  // external resistance -- pull up resistance
  pullup(scl);
  pullup(sda);
  
  // clock generation
  initial begin
    clk = 0;
    forever #10 clk = ~clk;
  end
  
  initial begin
    forever begin
      @(scl or negedge scl);
      #1;
      $display("Time = %0t | rst = %0d | nack = %0d | busy = %0d | SCL = %0d | SDA = %0d | data_out = %0d | done = %0d | mas_st = %0d | slv_st = %0d | slvadd = %0d(%0b)| mstadd = %0d(%0b)", $time, rst, ack_err, busy, scl, sda, data_out, done, dut.master.state, dut.slave.state, dut.slave.addr_sft_reg, dut.slave.addr_sft_reg, dut.master.addr_sft_reg, dut.master.addr_sft_reg);
    end
  end
    
  
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars;
    
    // initialize
    rst 		= 0;
    i2c_clk_en 	= 1;
    rw 			= 0;
    addr 		= 0;
    data_in 	= 0;
    i2c_en 		= 0;
    
    #200 rst = 1; 	// dessert
    
    run_task(33, 0, 145);
    
    
    #5000; 
    
    $display("\n------------------------- Accessing wrong slave -- to check nack");
    run_task(6, 0, 27);
    
    #5000;
    $finish;
  end
  
  // task run
  task run_task(
    input [ADDRESS_WIDTH-1:0] slv_addr,
    input 					  rw_sign,
    input [DATA_WIDTH-1:0]	  ms2slv_data
  );
    begin
      @(posedge clk);
      addr 	  = slv_addr;
      rw   	  = rw_sign;
      data_in = ms2slv_data;
      
      $display("\t\t --------------- sending address ,rw, data ---------------");
      $display("\t\t time = %0t | addr = %0d(%b) | rw = %0d | data_in = %0d(%b)", $time, addr, addr, rw, data_in, data_in);
      
      i2c_en = 1;
      
      // master start
      fork 
        begin
          @(posedge busy);
          i2c_en = 0;		// i2c protocol enable
        end
        begin
          repeat(1000) @(posedge clk);
          if (!busy) $display("TIMEOUT: Master never started");
        end
      join_any
      
      @(negedge busy);
      #100;
      
      if((data_out == data_in) && !ack_err)
        $display("\t\t SUCCESS: sent = %0d Received %d correctly", data_in, data_out);
      else
        $display("\t\t ERROR: Data mismatch or address mismatch ---- ack_err=%d", ack_err);
      #20;
    end
  endtask
    
endmodule