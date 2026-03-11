// APB - MASTER

module apb_master #(parameter DEPTH      = 256,
                    parameter ADDR_WIDTH  = 16,		// 12 address bits and 4 slave select bits
                    parameter DATA_WIDTH = 32) (	// data width
               
  // system 
  input 						 pclk,
  input 						 presetn,			// asynchronous reset
  
  // input control signals
  // dummy input signals from AHB
  input [DATA_WIDTH-1:0]		 apb_pwdata,			// apb write data
  input [ADDR_WIDTH-1:0]		 apb_pwaddr,			// apb write address + slave select lsb 4bits
  input [ADDR_WIDTH-1:0]		 apb_praddr,			// apb read address + slave select lsb 4bits
  input 						 apb_pwrite,			// apb read/ write signal -- write - 1, read - 0
  input 						 apb_tx_enable,		// apb master transmission enable
  
  // input pins from slave
  input [DATA_WIDTH-1:0]		 prdata,				// read data
  input 						 pready,				// slave ready signal
  input		 					 pslverr,			// peripheral transmission failed -- error
  
  // output status signal -- to slave
  output reg 					 psel,				// slave select
  output reg [ADDR_WIDTH-1:0]    paddr,				// peripheral address
  output reg [DATA_WIDTH-1:0]	 pwdata,			// peripheral write data
  output reg 					 pwrite,			// peripheral read/write command --- write - 1, read - 0
  output reg 					 penable, 		// peripheral slave enable
  output    					 busy,
  output reg [DATA_WIDTH-1:0]	 apb_prdata			// apb read data
); 
  
  // parameter for states
  parameter [1:0] IDLE   = 0,
  				  SETUP  = 1,
  				  ACCESS = 2;
  reg [1:0]state, next_state;
  
  // sequential block -- Next state transistion
  always @(posedge pclk or negedge presetn) begin 	// asynchronous reset
    if(!presetn)			// active low reset
      state <= IDLE;
    else
      state <= next_state;
  end
  
  // sequential block -- output data transmission -- read/ write
  always @(posedge pclk or negedge presetn) begin 	// asynchronous reset
    if(!presetn) begin			// active low reset
      apb_prdata <= 0;
      psel   	 <= 0;
      paddr  	 <= 0;
      pwdata 	 <= 0;
      pwrite 	 <= 0;
      penable    <= 0;
    end
    
    else begin
      case(state)
        // ----------- IDLE -----------
        IDLE : begin
          psel 	  <= 0;
          penable <= 0;
        end
        
        // ----------- SETUP -----------
        SETUP : begin
          psel 	  <= 1;
          penable <= 0;
          pwrite  <= apb_pwrite;
          
          if(apb_pwrite) begin	// write data to the slave memory
            paddr  <= apb_pwaddr;
            pwdata <= apb_pwdata;
          end
          else					// read address
            paddr <= apb_praddr;
        end
      
        // ----------- ACCESS -----------
        ACCESS : begin
          psel 	  <= 1;
          penable <= 1;
          if(!apb_pwrite && pready)
            apb_prdata <= prdata;			//read data from slave
        end
      endcase
    end
  end
  
  // combinational block for Next state logic 
  always @(*) begin
    case(state)
      IDLE   : next_state = (apb_tx_enable) ? SETUP : IDLE;
      SETUP  : next_state = ACCESS;
      ACCESS : next_state = ((pready) ? ((apb_tx_enable) ? SETUP : IDLE) : ACCESS);
    endcase
  end
  
  assign busy = !(state == IDLE);
  
endmodule
