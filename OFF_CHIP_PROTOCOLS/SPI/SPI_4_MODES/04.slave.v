// SPI -- slave

module spi_slave #(parameter DATA_WIDTH = 8) (
  
  // system
  input 				  	  clk,
  input 				  	  rst,
  
  // input control signals
  input 					  CPOL,		// clock polarity -- clock starting
  input 					  CPHA,					// clock phase
  input 				  	  cs,
  input 				  	  SIMO,			// master out slave in
  input 				  	  SCLK,
  input [DATA_WIDTH-1:0] 	  tx_datain,		// transmission data
  
  // output status signals
  output    				  SOMI,			// master in slave out
  output reg 				  done,
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
  				  ACTIVE   = 1,
  				  STOP     = 2;
  reg [1:0] state;
  
  // SCLK clock edge detection
  reg [1:0]sclk_sync;
  
  always @(posedge clk) begin
    sclk_sync <= {sclk_sync[0], SCLK};
  end
  
  wire rising_edge = sclk_sync == 2'b01;
  wire falling_edge = sclk_sync == 2'b10;
  
  // high impedance cs line
  reg somi_drive;
  assign SOMI = (cs == 0) ? (somi_drive) : 1'bz;
  
  // SPI mode -- clock phase
  reg drive, sample;
  wire [1:0] spi_mode = {CPOL, CPHA};
  
  always @(*) begin
    case(spi_mode)
      2'b00 : begin				// mode 0
        sample = rising_edge; 
        drive  = falling_edge;
      end
      
      2'b01 : begin				// mode 1
        sample = falling_edge;
        drive  = rising_edge;
      end
      
      2'b10 : begin				// mode 2
        sample = falling_edge;
        drive  = rising_edge;
      end
      
      2'b11 : begin				// mode 3
        sample = rising_edge;
        drive  = falling_edge;
      end
      
      default : begin			// default mode 0
        sample = rising_edge; 
        drive  = falling_edge;
      end
    endcase
  end      
  
  // spi data transfer and receive FSM
  always @(posedge clk or posedge rst) begin
    if(rst) begin
      somi_drive	<= 0;
      done			<= 0;
      rx_dataout	<= 0;
      data_count	<= 0;
      tx_shift_reg	<= 0;
      rx_shift_reg	<= 0;
      state 		<= IDLE;
    end
    else begin
      case(state)
        IDLE : begin
          if(cs) begin
            somi_drive	    <= 0;
      		done	    <= 0;
      		data_count	<= DATA_WIDTH-1;
      		tx_shift_reg <= tx_datain;		// loading tx data to register
     		rx_shift_reg <= 0;
          end
          else if(!cs) begin
//             if(CPHA == 0) begin
              somi_drive <= tx_shift_reg[DATA_WIDTH-1];	// pre-load msb bit
              tx_shift_reg <= {tx_shift_reg[DATA_WIDTH-2:0], 1'b0};
//             end
            state <= ACTIVE;
            
          end
        end
        
        ACTIVE : begin
                    
          if(drive) begin		// drive
            somi_drive <= tx_shift_reg[DATA_WIDTH-1];
            tx_shift_reg <= {tx_shift_reg[DATA_WIDTH-2:0], 1'b0};
          end
          
          if(sample) begin		// sample
            rx_shift_reg <= {rx_shift_reg[DATA_WIDTH-2:0],SIMO};
            if(data_count == 0) begin
            data_count <= DATA_WIDTH - 1;
            state <= STOP;
            end
            else
              data_count <= data_count - 1;
          end
        end
        
        STOP : begin
          if(cs) begin
            done <= 1;
            rx_dataout <= rx_shift_reg;
            somi_drive <= 0;
            state <= IDLE;
          end
        end
        
        default : state <= IDLE;
      endcase
    end
  end
endmodule