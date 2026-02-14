// SPI(Serial Peripheral Interface) -- master

module spi_master #(parameter DATA_WIDTH = 8) (
  
  // system
  input 				  	  clk,
  input 				  	  rst,
  
  // input control signals
  input 				  	  spi_enable,				// spi start signal
  input 				  	  spi_clock_tick,
  input [DATA_WIDTH-1:0] 	  tx_datain,		// transmission data
  input 				  	  MISO,				// master in slave out
  
  // output status signals
  output reg 				  MOSI,			// master out slave in
  output    				  SCLK,			// serial clock
  output reg 				  cs,			// ss/cs -- slave / chip select
  output reg 				  busy,
  output reg [DATA_WIDTH-1:0] rx_dataout		// received data
);
  
  // internal counter & register
  localparam DATA_CNT_WDH = $clog2(DATA_WIDTH);
  
  reg [DATA_CNT_WDH:0] data_count;		// data counter
  
  // shift register
  reg [DATA_WIDTH-1:0] tx_shift_reg;
  reg [DATA_WIDTH-1:0] rx_shift_reg;
  
  // parameter states
  parameter [1:0] IDLE     = 0,
  				  START    = 1,
  				  TRANSFER = 2,
  				  STOP     = 3;
  reg [1:0] state;
  
  // SCLK clock control -- for slave 
  reg sclk_en;
  assign SCLK = (sclk_en) ? spi_clock_tick : 1'b0;
  
  
  // SCLK clock edge detection
  reg spi_clk_d;
  
  always @(posedge clk) begin
    spi_clk_d <= spi_clock_tick;
  end
  
  wire rising_edge = ~spi_clk_d && spi_clock_tick;
  wire falling_edge = spi_clk_d && ~spi_clock_tick;
  
  always @(posedge clk or posedge rst) begin
    if(rst) begin
      state 	   <= IDLE;		// default state idle
      busy		   <= 0;
      rx_dataout   <= 0;
      cs 		   <= 1;
      sclk_en 	   <= 0;
      data_count   <= 0;
      tx_shift_reg <= 0;
      rx_shift_reg <= 0;
      MOSI		   <= 0;
    end
    else begin
      case(state)
        IDLE : begin
          MOSI		   <= 0;
          busy 	  	   <= 0;
          cs 	  	   <= 1;
          sclk_en 	   <= 0;
          tx_shift_reg <= 0;
      	  rx_shift_reg <= 0;
          if(spi_enable && cs)
            state <= START;
        end
        
        START : begin
          busy <= 1;
          cs <= 0;
          sclk_en <= 1;		// sclk enable
          
          // pre shift 
          tx_shift_reg <= {tx_datain[DATA_WIDTH-2:0], 1'b0};
          
          data_count <= DATA_WIDTH-1;
          MOSI <= tx_datain[DATA_WIDTH-1];		// loading msb bit immediately
          state <= TRANSFER;
        end
        
        TRANSFER : begin
                    
          if(falling_edge) begin		// drive data
            MOSI <= tx_shift_reg[DATA_WIDTH-1];
            tx_shift_reg <= {tx_shift_reg[DATA_WIDTH-2:0], 1'b0};
          end
                             
          
          if(rising_edge) begin		// sample 
            rx_shift_reg <= {rx_shift_reg[DATA_WIDTH-2:0], MISO};
            if(data_count == 0) begin
            data_count <= DATA_WIDTH - 1;
            state <= STOP;
            end
            else
              data_count <= data_count - 1;
          end
        end
        
        STOP : begin
          cs <= 1;
          sclk_en <= 0;		// disable sclk
          rx_dataout <= rx_shift_reg;
          busy <= 0;
          state <= IDLE;
          MOSI <= 0;
        end
        
        default : state <= IDLE;
      endcase
    end
  end
endmodule