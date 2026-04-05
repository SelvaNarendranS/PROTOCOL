// I2C top module -- write and read operation
`include "clock_divider.v"
`include "master.v"
`include "slave.v"

module i2c_top_module #(
  parameter SYS_CLK 	  = 50_000_000,		// hz - in hertz(mhz)
  parameter I2C_CLK 	  = 100_000,		// hz - in hertz(mhz)
  parameter ADDRESS_WIDTH = 7,
  parameter DATA_WIDTH    = 8,
  parameter SLAVE_ADDR 	  = 32)				// fixed lave address
  (
    // system
    input 					  clk,
    input 					  rst,
    
    // control input signals
    input 					  i2c_clk_en,	// i2c clock generator enable
    input 					  i2c_en,		// i2c protocal enable
    input [ADDRESS_WIDTH-1:0] addr,
    input 					  rw,			// read - 1, write - 0 ---> read & write command
    input [DATA_WIDTH-1:0]	  mas_data_in,		// master input data for transmission
    input [DATA_WIDTH-1:0]	  slv_data_in,		// slave input data for transmission
    
    // result output signal
    output 					  busy,
    output				  	  ack_err,		// acknowledgement error - not ack
    output 					  done,
    output [DATA_WIDTH-1:0]   mas_data_out,		// master output data -- received data
    output [DATA_WIDTH-1:0]   slv_data_out,		// slave output data -- received data
    inout				  scl,			// serial clock
    inout				  sda			// serial data
  );
  
  // internal wire
  wire scl_tick;
  wire scl_clk;
  
  // instantation
  
  // clock divider
  i2c_clock_divider #(.SYS_CLK(SYS_CLK),
                      .I2C_CLK(I2C_CLK))
  receiver( 
    .clk(clk),
    .rst(rst),
    .i2c_clk_en(i2c_clk_en),
    .scl_tick(scl_tick),
    .scl_out(scl_clk)
  );
  
  // master
  i2c_master #(.ADDRESS_WIDTH(ADDRESS_WIDTH),
               .DATA_WIDTH(DATA_WIDTH))
  master(
    .clk(clk),
    .rst(rst),
    .scl_tick(scl_tick),
    .scl_clk(scl_clk),
    .i2c_en(i2c_en),
    .addr(addr),
    .rw(rw),
    .data_in(mas_data_in),
    .data_out(mas_data_out),
    .busy(busy),
    .ack_err(ack_err),
    .scl(scl),
    .sda(sda)
  );
  
  // slave
  i2c_slave #(.ADDRESS_WIDTH(ADDRESS_WIDTH),
              .DATA_WIDTH(DATA_WIDTH),
              .SLAVE_ADDR(SLAVE_ADDR))
  slave(
    .clk(clk),
    .rst(rst),
    .done(done),
    .data_in(slv_data_in),
    .data_out(slv_data_out),
    .scl(scl),
    .sda(sda)
  );
endmodule

// https://www.edaplayground.com/x/NM27
