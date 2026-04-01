// I2C clock divider
module i2c_clock_divider #(
  parameter SYS_CLK = 50_000_000,		// hz - in hertz(mhz)
  parameter I2C_CLK = 100_000)			// hz - in hertz(khz)
  (
    // system
    input 		clk,
    input 		rst,
    
    // input control signal
    input 		i2c_clk_en,		// i2c clock generator enable
    
    // status output signal
    output reg 	scl_out,
    output reg 	scl_tick		// provides clock for master ans slave for data transmission and receive 
  );
  
  // clock cycle calculation
  // required no of system clock to achive i2c_frequency
  localparam integer divider = (SYS_CLK / I2C_CLK * 2);	
  								// *2 to seprate clk HIGH & LOW
  
  // internal counter
  localparam DIV_WIDTH = $clog2(divider+1);
  
  reg [DIV_WIDTH-1:0] scl_count;
  
  // I2C clock generation
  always @(posedge clk or negedge rst) begin
    if(!rst) begin			// active low rst
      scl_count <= 0;		// resetting the scl clock counter
      scl_tick	<= 0;		// setting scl clock tick to low
      scl_out	<= 1;
    end
    else begin
      scl_tick <= 0;			// setting scl clock tick to low
      if(i2c_clk_en)begin
        if(scl_count == divider-1) begin
          scl_count <= 0;		// resetting the scl clock counter
          scl_tick  <= 1;		// setting scl clock tick to high
          scl_out	<= ~scl_out;
        end
        else begin
          scl_count <= scl_count + 1;
        end
      end
      else begin
        scl_count <= 0;
        scl_out	  <= 1;
      end
    end
  end
endmodule