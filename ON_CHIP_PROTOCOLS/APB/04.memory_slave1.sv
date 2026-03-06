// APB - SLAVE - 1

module apb_slave1 #(parameter DATA_WIDTH = 32,		// data width
                    parameter SLAVE_MODE = 2,		// mode = 0 -> read only register, mode = 1 -> write only register, mode = 2 -> both read/write register
                    parameter DEPTH       = 256,
                    parameter ADDR_WIDTH  = 16)(		// 12 address bits and 4 slave select bits
  
  // system 
  input 						pclk,
  input 						presetn,			// asynchronous reset
  
  // input control signals from master
  input 						psel,				// slave select
  input [ADDR_WIDTH-1:0]		paddr,				// peripheral address
  input [DATA_WIDTH-1:0]		pwdata,			// peripheral write data
  input 						pwrite,			// peripheral read/write command --- write - 1, read - 0
  input 						penable, 		// peripheral slave enable
  
  // output status signal
  output reg [DATA_WIDTH-1:0]	prdata,				// read data
  output reg 					pready,				// slave ready signal
  output reg		 			pslverr			// peripheral transmission failed -- error
);
  
  localparam DEPTH1 = ({ADDR_WIDTH{1'b1}} + 1);
  
  // slave memory to store the data's at the specified address
  reg [DATA_WIDTH-1:0] mem [0:DEPTH1-1];
  
  // error detection
  wire addr_error     = (paddr > DEPTH);
  wire mode_error     = (SLAVE_MODE > 2);		// 0:RO, 1:WO, 2:RW
  wire error_detected = addr_error || mode_error;		// error found
  
  // memory read and write
  always @(posedge pclk or negedge presetn) begin 	// asynchronous reset
    if(!presetn) begin			// active low reset
      prdata  <= 0;
      pready  <= 0;
      pslverr <= 0;
    end   
    else begin
      // default values
      pready  <= 0;
      pslverr <= 0;
     
      if((psel == 1'b1) && penable) begin
        pready <= 1;
        
        if(error_detected) begin
          pslverr <= 1;
        end
        else begin
          if(pwrite)
            mem[paddr] <= pwdata;			// write
          else
            prdata <= mem[paddr];			// read
        end
      end
    end
  end
  
endmodule