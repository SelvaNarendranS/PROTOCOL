// APB SLAVE MUX

module apb_slv_mux #(parameter DATA_WIDTH   = 8,
                     parameter ADDR_WIDTH  = 16)(		// 12 address bits and 4 slave select bits
  
  input 	   			 mas_psel,	// slave select signal(to enable the decoder logic)
  input [ADDR_WIDTH-1:0] paddr,		// address from the master
  output reg   			 psel1,		// 0x0FFF -- slave 1 select
  output reg   			 psel2,		// 0x2FFF -- slave 2 select
  output reg   			 psel3		// 0x2FFF -- output to slave3 -- slave selection
);
  	
  always @(*) begin
    // Default values if no slaves selected
    psel1 = 0;
    psel2 = 0;
    psel3 = 0;
    
    if(mas_psel) begin
      case(paddr[15:12])	// Higher bits is used for slave selection -- decoding
        4'h0 : psel1 = 1;	// slave1 range - 0x0000 to 0x0FFF
        4'h1 : psel2 = 1;
        4'h2 : psel3 = 1;	// slave3 range - 0x3FFF to 0x2FFF
        default : begin
          psel1 = 0;
    	  psel2 = 0;
    	  psel3 = 0;
	  end
        
      endcase
    end
  end
          
endmodule