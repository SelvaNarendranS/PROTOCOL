// SPI(Serial Peripheral Interface) -- top_module 
`include "clock_divider.v"
`include "master.v"
`include "slave.v"

module spi_top_module #(parameter DATA_WIDTH = 8,
                        parameter SYS_CLK = 10_000_000,	// 10mhz
                        parameter SPI_CLK = 5_000_000)(	// 5mhz
  
  input clk,
  input rst,
  input sclk_gen_en,
  output sclk_tick,
  
  input 				  	  spi_enable,				// spi start signal
  input [DATA_WIDTH-1:0] 	  master_tx_datain,		// transmission data
  
  output reg 				  busy,
  output reg [DATA_WIDTH-1:0] master_rx_dataout,
  
  input [DATA_WIDTH-1:0] 	  slave_tx_datain,
  
  output reg 				  done,
  output reg [DATA_WIDTH-1:0] slave_rx_dataout
);
  
  wire spi_clock_tick, SOMI, SIMO, S_cs, S_SCLK;
  assign sclk_tick = spi_clock_tick;
  
  // instantation
  spi_clock_divider #(.SYS_CLK(SYS_CLK),
                      .SPI_CLK(SPI_CLK)) 
  clock_div (.clk(clk),
             .rst(rst),
             .sclk_gen_en(sclk_gen_en),
             .sclk_tick(spi_clock_tick)
            );
  
  spi_master #(.DATA_WIDTH(DATA_WIDTH))
  master (.clk(clk),
          .rst(rst),
          .spi_enable(spi_enable),
          .spi_clock_tick(spi_clock_tick),
          .tx_datain(master_tx_datain),
          .MISO(SOMI),
          .MOSI(SIMO),
          .SCLK(S_SCLK),
          .cs(S_cs),
          .busy(busy),
          .rx_dataout(master_rx_dataout)
         );
  
  spi_slave #(.DATA_WIDTH(DATA_WIDTH))
  slave (.clk(clk),
         .rst(rst),
         .cs(S_cs),
         .SIMO(SIMO),
         .SCLK(S_SCLK),
         .tx_datain(slave_tx_datain),
         .SOMI(SOMI),
         .done(done),
         .rx_dataout(slave_rx_dataout)
        );
  
endmodule