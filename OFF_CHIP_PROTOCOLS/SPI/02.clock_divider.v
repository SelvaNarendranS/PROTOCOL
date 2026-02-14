// SPI(Serial Peripheral Interface) -- clock divider

module spi_clock_divider #(parameter SYS_CLK = 10_000_000,	// 10mhz
                           parameter SPI_CLK = 5_000_000)(	// 5mhz
  
  // system
  input  	 clk,		// system clock
  input  	 rst,
  
  // input control signal
  input  	 sclk_gen_en,
  
  // output status signal
  output reg sclk_tick
);
  
  // clock cycle calculation
  // required no.of system clock to acquire required clock speed 
  localparam divider = SYS_CLK /(SPI_CLK * 2);	// *2 --> HIGH + LOW
  
  // internal counter
  localparam SPI_CLK_WIDTH = $clog2(divider);		// spi counter width 1/2 of cycle
  
  reg [SPI_CLK_WIDTH-1:0]clk_count;		// clock counter
  
  always @(posedge clk or posedge rst) begin
    if(rst) begin			// active high reset
      sclk_tick <= 0;
      clk_count <= 0;
    end
    else if(sclk_gen_en) begin
      if(clk_count == divider - 1) begin
        clk_count <= 0;		// resetting the clock counter
        sclk_tick <= 1;		// clock tick
      end
      else begin
        clk_count <= clk_count + 1;	// incrementing the clock counter
        sclk_tick <= 0;
      end
    end
  end
endmodule